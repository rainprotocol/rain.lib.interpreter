// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

import "rain.solmem/lib/LibPointer.sol";
import "rain.solmem/lib/LibStackPointer.sol";
import "rain.datacontract/lib/LibDataContract.sol";
import "rain.factory/src/lib/LibIERC1820.sol";

import "../interface/unstable/IExpressionDeployerV2.sol";
import "../interface/unstable/IDebugExpressionDeployerV1.sol";
import "../interface/unstable/IDebugInterpreterV1.sol";
import "../interface/unstable/IParserV1.sol";

import "../lib/integrity/LibIntegrityCheck.sol";
import "../lib/state/LibInterpreterStateDataContract.sol";
import "../lib/op/LibAllStandardOpsNP.sol";
import "../lib/parse/LibParse.sol";

/// @dev Thrown when the pointers known to the expression deployer DO NOT match
/// the interpreter it is constructed for. This WILL cause undefined expression
/// behaviour so MUST REVERT.
/// @param actualPointers The actual function pointers found at the interpreter
/// address upon construction.
error UnexpectedPointers(bytes actualPointers);

/// Thrown when the `RainterpreterExpressionDeployer` is constructed with unknown
/// interpreter bytecode.
/// @param actualBytecodeHash The bytecode hash that was found at the interpreter
/// address upon construction.
error UnexpectedInterpreterBytecodeHash(bytes32 actualBytecodeHash);

/// @dev There are more entrypoints defined by the minimum stack outputs than
/// there are provided sources. This means the calling contract WILL attempt to
/// eval a dangling reference to a non-existent source at some point, so this
/// MUST REVERT.
error MissingEntrypoint(uint256 expectedEntrypoints, uint256 actualEntrypoints);

/// Thrown when the `Rainterpreter` is constructed with unknown store bytecode.
/// @param actualBytecodeHash The bytecode hash that was found at the store
/// address upon construction.
error UnexpectedStoreBytecodeHash(bytes32 actualBytecodeHash);

/// Thrown when the `Rainterpreter` is constructed with unknown opMeta.
error UnexpectedOpMetaHash(bytes32 actualOpMeta);

/// Thrown when the integrity check returns a negative stack index.
/// @param index The negative index.
error NegativeStackIndex(int256 index);

/// @dev The function pointers known to the expression deployer. These are
/// immutable for any given interpreter so once the expression deployer is
/// constructed and has verified that this matches what the interpreter reports,
/// it can use this constant value to compile and serialize expressions.
bytes constant OPCODE_FUNCTION_POINTERS = hex"0afa";

/// @dev Hash of the known interpreter bytecode.
bytes32 constant INTERPRETER_BYTECODE_HASH = bytes32(0xdfbbdaf24b08f29aef5b5dc337e7f3342da8225b8a830d0d7d5b5d0467507f2b);

/// @dev Hash of the known store bytecode.
bytes32 constant STORE_BYTECODE_HASH = bytes32(0xd6130168250d3957ae34f8026c2bdbd7e21d35bb202e8540a9b3abcbc232ddb6);

/// @dev Hash of the known op meta.
bytes32 constant OP_META_HASH = bytes32(0x2cf73adad61aae49cfe0a38448ca982e30a16b18fe56c294e51104f9148d94da);

/// All config required to construct a `Rainterpreter`.
/// @param interpreter The `IInterpreterV1` to use for evaluation. MUST match
/// known bytecode.
/// @param store The `IInterpreterStoreV1`. MUST match known bytecode.
/// @param meta The meta emitted for offchain tooling. Traditionally this was
/// mainly opmeta, used for the offchain compiler, but now with an onchain
/// compiler the meta content and format is open to experimentation.
struct RainterpreterExpressionDeployerConstructionConfig {
    address interpreter;
    address store;
    bytes meta;
}

/// @title RainterpreterExpressionDeployer
/// @notice !!!EXPERIMENTAL!!! This is the deployer for the RainterpreterNP
/// interpreter. Notably includes onchain parsing/compiling of expressions from
/// Rainlang strings.
contract RainterpreterExpressionDeployerNP is IExpressionDeployerV2, IDebugExpressionDeployerV1, IParserV1, ERC165 {
    using LibStackPointer for Pointer;
    using LibUint256Array for uint256[];

    /// The config of the deployed expression including uncompiled sources. Will
    /// only be emitted after the config passes the integrity check.
    /// @param sender The caller of `deployExpression`.
    /// @param sources As per `IExpressionDeployerV1`.
    /// @param constants As per `IExpressionDeployerV1`.
    /// @param minOutputs As per `IExpressionDeployerV1`.
    event NewExpression(address sender, bytes[] sources, uint256[] constants, uint8[] minOutputs);

    /// The address of the deployed expression. Will only be emitted once the
    /// expression can be loaded and deserialized into an evaluable interpreter
    /// state.
    /// @param sender The caller of `deployExpression`.
    /// @param expression The address of the deployed expression.
    event ExpressionAddress(address sender, address expression);

    /// The interpreter with known bytecode that this deployer is constructed
    /// for.
    IInterpreterV1 public immutable iInterpreter;
    /// The store with known bytecode that this deployer is constructed for.
    IInterpreterStoreV1 public immutable iStore;

    constructor(RainterpreterExpressionDeployerConstructionConfig memory config) {
        // Set the immutables.
        IInterpreterV1 interpreter = IInterpreterV1(config.interpreter);
        IInterpreterStoreV1 store = IInterpreterStoreV1(config.store);
        iInterpreter = interpreter;
        iStore = store;

        // Guard against serializing incorrect function pointers, which would
        // cause undefined runtime behaviour for corrupted opcodes.
        bytes memory functionPointers = interpreter.functionPointers();
        if (keccak256(functionPointers) != keccak256(OPCODE_FUNCTION_POINTERS)) {
            revert UnexpectedPointers(functionPointers);
        }
        // Guard against an interpreter with unknown bytecode.
        bytes32 interpreterHash;
        assembly ("memory-safe") {
            interpreterHash := extcodehash(interpreter)
        }
        if (interpreterHash != INTERPRETER_BYTECODE_HASH) {
            /// THIS IS NOT A SECURITY CHECK. IT IS AN INTEGRITY CHECK TO PREVENT
            /// HONEST MISTAKES.
            revert UnexpectedInterpreterBytecodeHash(interpreterHash);
        }

        // Guard against an store with unknown bytecode.
        bytes32 storeHash;
        assembly ("memory-safe") {
            storeHash := extcodehash(store)
        }
        if (storeHash != STORE_BYTECODE_HASH) {
            /// THIS IS NOT A SECURITY CHECK. IT IS AN INTEGRITY CHECK TO PREVENT
            /// HONEST MISTAKES.
            revert UnexpectedStoreBytecodeHash(storeHash);
        }

        /// This IS a security check. This prevents someone making an exact
        /// bytecode copy of the interpreter and shipping different meta for
        /// the copy to lie about what each op does in the interpreter.
        bytes32 opMetaHash = keccak256(config.meta);
        if (opMetaHash != OP_META_HASH) {
            revert UnexpectedOpMetaHash(opMetaHash);
        }

        emit DISpair(msg.sender, address(this), address(interpreter), address(store), config.meta);

        IERC1820_REGISTRY.setInterfaceImplementer(
            address(this), IERC1820_REGISTRY.interfaceHash(IERC1820_NAME_IEXPRESSION_DEPLOYER_V1), address(this)
        );
    }

    // @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return interfaceId_ == type(IExpressionDeployerV1).interfaceId || interfaceId_ == type(IERC165).interfaceId;
    }

    /// @inheritdoc IDebugExpressionDeployerV1
    function offchainDebugEval(
        bytes[] memory sources,
        uint256[] memory constants,
        FullyQualifiedNamespace namespace,
        uint256[][] memory context,
        SourceIndex sourceIndex,
        uint256[] memory initialStack,
        uint8 minOutputs
    ) external view returns (uint256[] memory, uint256[] memory) {
        IntegrityCheckState memory integrityCheckState =
            LibIntegrityCheck.newState(sources, constants, integrityFunctionPointers());
        Pointer stackTop = integrityCheckState.stackBottom;
        stackTop = LibIntegrityCheck.push(integrityCheckState, stackTop, initialStack.length);
        {
            Pointer stackTopAfter =
                LibIntegrityCheck.ensureIntegrity(integrityCheckState, sourceIndex, stackTop, minOutputs);
            (stackTopAfter);
        }

        uint256[] memory stack;
        {
            int256 stackLength = integrityCheckState.stackBottom.toIndexSigned(integrityCheckState.stackMaxTop);
            if (stackLength < 0) {
                revert NegativeStackIndex(stackLength);
            }
            for (uint256 i_; i_ < sources.length; i_++) {
                LibCompile.unsafeCompile(sources[i_], OPCODE_FUNCTION_POINTERS);
            }
            stack = new uint256[](uint256(stackLength));
            LibMemCpy.unsafeCopyWordsTo(initialStack.dataPointer(), stack.dataPointer(), initialStack.length);
        }

        // The return is used by returning it, so this is a false positive.
        //slither-disable-next-line unused-return
        return IDebugInterpreterV1(address(iInterpreter)).offchainDebugEval(
            iStore, namespace, sources, constants, context, stack, sourceIndex
        );
    }

    /// @inheritdoc IParserV1
    function parse(bytes memory data) external pure returns (bytes[] memory, uint256[] memory) {
        bytes32[] memory words = new bytes32[](1);
        words[0] = "chain-id";
        // The return is used by returning it, so this is a false positive.
        //slither-disable-next-line unused-return
        return LibParse.parse(data, LibParseMeta.buildMetaExpander(words, 2));
    }

    /// @inheritdoc IExpressionDeployerV2
    function deployExpression(bytes[] memory sources, uint256[] memory constants, uint8[] memory minOutputs)
        external
        returns (IInterpreterV1, IInterpreterStoreV1, address)
    {
        uint256 stackLength = integrityCheck(sources, constants, minOutputs);

        // Emit the config of the expression _before_ we serialize it, as the
        // serialization process itself is destructive of the sources in memory.
        emit NewExpression(msg.sender, sources, constants, minOutputs);

        (DataContractMemoryContainer container, Pointer pointer) =
            LibDataContract.newContainer(LibInterpreterStateDataContract.serializeSize(sources, constants));

        // Serialize the state config into bytes that can be deserialized later
        // by the interpreter. This will compile the sources according to the
        // provided function pointers.
        LibInterpreterStateDataContract.unsafeSerialize(
            pointer, sources, constants, stackLength, OPCODE_FUNCTION_POINTERS
        );

        // Deploy the serialized expression onchain.
        address expression = LibDataContract.write(container);

        // Emit and return the address of the deployed expression.
        emit ExpressionAddress(msg.sender, expression);

        return (iInterpreter, iStore, expression);
    }

    /// Drives an integrity check of the provided sources and constants. This
    /// @param sources The sources to check.
    /// @param constants The constants to check.
    /// @param minOutputs The minimum number of outputs expected from each of
    /// the sources. Only applies to sources that are entrypoints. Internal
    /// sources have their integrity checked implicitly by the use of opcodes
    /// such as `call` that have min/max outputs in their operand.
    /// @return The total stack size required to fully evaluate the expression.
    /// This is used to allocate the stack when deserializing the expression
    /// later so MUST be correct for ALL internal states of the evaluation. It
    /// is NOT sufficient to just return the final stack size as the stack
    /// grows and shrinks during evaluation.
    function integrityCheck(bytes[] memory sources, uint256[] memory constants, uint8[] memory minOutputs)
        internal
        view
        returns (uint256)
    {
        // Ensure that we are not missing any entrypoints expected by the calling
        // contract.
        if (minOutputs.length > sources.length) {
            revert MissingEntrypoint(minOutputs.length, sources.length);
        }

        // Build the initial state of the integrity check.
        IntegrityCheckState memory integrityCheckState =
            LibIntegrityCheck.newState(sources, constants, integrityFunctionPointers());
        // Loop over each possible entrypoint as defined by the calling contract
        // and check the integrity of each. At the least we need to be sure that
        // there are no out of bounds stack reads/writes and to know the total
        // memory to allocate when later deserializing an associated interpreter
        // state for evaluation.
        Pointer initialStackBottom = integrityCheckState.stackBottom;
        Pointer initialStackHighwater = integrityCheckState.stackHighwater;
        for (uint16 i_ = 0; i_ < minOutputs.length; i_++) {
            // Reset the top, bottom and highwater between each entrypoint as
            // every external eval MUST have a fresh stack, but retain the max
            // stack height as the latter is used for unconditional memory
            // allocation so MUST be the max height across all possible
            // entrypoints.
            integrityCheckState.stackBottom = initialStackBottom;
            integrityCheckState.stackHighwater = initialStackHighwater;
            Pointer stackTopAfter = LibIntegrityCheck.ensureIntegrity(
                integrityCheckState, SourceIndex.wrap(i_), INITIAL_STACK_BOTTOM, minOutputs[i_]
            );
            (stackTopAfter);
        }

        int256 finalMaxIndex = integrityCheckState.stackBottom.toIndexSigned(integrityCheckState.stackMaxTop);
        if (finalMaxIndex < 0) {
            revert NegativeStackIndex(finalMaxIndex);
        }
        return uint256(finalMaxIndex);
    }

    /// Defines all the function pointers to integrity checks. This is the
    /// expression deployer's equivalent of the opcode function pointers and
    /// follows a near identical dispatch process. These are never compiled into
    /// source and are instead indexed into directly by the integrity check. The
    /// indexing into integrity pointers (which has an out of bounds check) is a
    /// proxy for enforcing that all opcode pointers exist at runtime, so the
    /// length of the integrity pointers MUST match the length of opcode function
    /// pointers. This function is `virtual` so that it can be overridden
    /// pairwise with overrides to `functionPointers` on `Rainterpreter`.
    /// @return The list of integrity function pointers.
    function integrityFunctionPointers()
        internal
        view
        virtual
        returns (function(IntegrityCheckState memory, Operand, Pointer) view returns (Pointer)[] memory)
    {
        return LibAllStandardOpsNP.integrityFunctionPointers();
    }
}
