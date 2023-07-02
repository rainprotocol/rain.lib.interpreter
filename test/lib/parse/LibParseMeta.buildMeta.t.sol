// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "src/lib/parse/LibParseMeta.sol";
import "test/lib/parse/LibBloom.sol";

contract LibParseMetaBuildMetaTest is Test {
    // function testBuildMeta0() external view {
    //     bytes32[] memory words = new bytes32[](2);
    //     words[0] = bytes32("a");
    //     words[1] = bytes32("b");
    //     bytes memory meta = LibParse.buildMeta(words, 0, 0x100);
    //     console2.logBytes(meta);
    // }

    // function testbuildMetaX() external {
    //     bytes32[] memory words = new bytes32[](2);
    //     words[0] = bytes32("a");
    //     words[1] = bytes32("b");
    //     assertEq(LibParse.buildMeta(words, 0, 0x100), LibParse.buildMetaSol(words));
    // }

    // function testBuildMeta1() external view {
    //     bytes32[] memory words = new bytes32[](70);
    //     for (uint256 i = 0; i < words.length; i++) {
    //         words[i] = bytes32(i);
    //     }
    //     bytes memory meta = LibParse.buildMeta(words, 0, 100000);
    //     console2.logBytes(meta);
    // }

    // function testBuildMetaY() external view {
    //     bytes32[] memory words = new bytes32[](170);
    //     for (uint256 i = 0; i < words.length; i++) {
    //         words[i] = bytes32(i);
    //     }
    //     bytes memory meta = LibParse.buildMetaSol2(words);
    //     console2.logBytes(meta);
    // }

    /// This is super loose from limited empirical testing.
    function expanderDepth(uint256 n) internal pure returns (uint8) {
        // Number of fully saturated expanders
        // + 1 for solidity flooring everything
        // + 1 for a non-fully saturated but still quite full expander
        // + 1 for a potentially nearly empty expander
        return uint8(n / type(uint8).max + 3);
    }

    function testBuildMetaExpander(bytes32[] memory words) external view {
        vm.assume(!LibBloom.bloomFindsDupes(words));
        bytes memory meta = LibParseMeta.buildMetaExpander(words, expanderDepth(words.length));
        (meta);
    }

    function testRoundMetaExpander(bytes32[] memory words, uint8 j, bytes32 notFound) external {
        vm.assume(words.length > 0);
        vm.assume(!LibBloom.bloomFindsDupes(words));
        for (uint256 i = 0; i < words.length; i++) {
            vm.assume(words[i] != notFound);
        }
        j = uint8(bound(j, uint8(0), uint8(words.length) - 1));

        bytes memory meta = LibParseMeta.buildMetaExpander(words, expanderDepth(words.length));
        (bool exists, uint256 k) = LibParseMeta.lookupIndexMetaExpander(meta, words[j]);
        assertTrue(exists);
        assertEq(j, k);

        (bool notExists, uint256 l) = LibParseMeta.lookupIndexMetaExpander(meta, notFound);
        assertTrue(!notExists);
        assertEq(0, l);
    }

    function testRoundMetaExpanderDeeper(bytes32[] memory words, uint8 j, bytes32 notFound) external {
        vm.assume(words.length > 50);
        vm.assume(!LibBloom.bloomFindsDupes(words));
        for (uint256 i = 0; i < words.length; i++) {
            vm.assume(words[i] != notFound);
        }
        j = uint8(bound(j, uint8(0), uint8(words.length) - 1));

        bytes memory meta = LibParseMeta.buildMetaExpander(words, expanderDepth(words.length));
        (bool exists, uint256 k) = LibParseMeta.lookupIndexMetaExpander(meta, words[j]);
        assertTrue(exists);
        assertEq(j, k);

        (bool notExists, uint256 l) = LibParseMeta.lookupIndexMetaExpander(meta, notFound);
        assertTrue(!notExists);
        assertEq(0, l);
    }

    // function testRoundMetaExpanderRegression() external {
    //     // bytes32[130] memory wordsFixed = [bytes32(uint256(129)), 0x0001000000040f00340200000000006837090100003b00010000000200000004, 0x0000070000000000000000000000000000000900000000000000000000000000, 0x1f0d00000000000e00600000000000020000015400002800030317000000001c, 0x0000000204050000030001000000043d0c3001021807445200010020014d0000, 0x004a02278100018b021b6806081c4d065b000b1a0a05050b1c180a16090102a5, 0x005c000000000000060700000200001d0000000000000000520000001c000015, 0x1100040000000100000000000000000000000c005d0000180101000000001500, 0x0002000200000000000000000001010204000000001b2400001c1a0000000000, 0x00200e00000000000000000007000000001c0000000000000200000000000000, 0x000000000000000013000000000000000000000000000000190000000d000000, 0x041e000002000000000200000003000000040000110200000000000000000004, 0x000000000000000000000000000000000000000006000000000000001a070000, 0x00000001001f0000000000000000000000000000000003000000001900000000, 0x00000000000000000003000e0e00000000000000007908000000000000000000, 0x0500040569ae262401440300530e007b0311435c1000010a1905011d1a0e1c00, 0x050d35381c0019104d0c0601183f503b6f00094d3283a9443c02040b10290005, 0x0003041400043337330e0002000001011c020300000c0a0072686289dc64dc85, 0x730879266eb07e2ebdb9cbc0754fed5d43a2c9ba55767b8451eb16006d9c175a, 0x957c22ec3b144d099c52a6af18d700fef8663aee09099471c22a622c65a67582, 0xde7b51a67b5733f5c2b076097c11d76d3bb1b3329a4ef93c9f63f184879e56e4, 0x7509ac2990a2c5cc49ed628c77bc61ad123bcb7d1eb08f7612ddd39e6cce3f72, 0x160b9f8ae8344a8525b3501acffbb3b55ccf8e5b18371245517dc0cb111a4868, 0x263d514b76f3713f7c223be875adbf5cf77701d7018f31a429c2d2f42e82a147, 0x4299a3ce5925f884f1c42a112be0e92947041611d908b211ffef49783fdf5186, 0xae0fd8d1084fc50009fc6490a901b4a97686f8f3825717a2c5ebca40d14dd61a, 0xefb146e521fd6a87af167dc10acdb153f2eeeeff90a3446496dd6355b64b0bd7, 0x149a8768c082600776f9f8d8f6f0258c6358534382df062c3a2f9c9d0e8f6ff0, 0xc340389ff7028ed045beb2d0db262cd359b61776490799d44977a697e24db7eb, 0x9bf1b0ba12077a326e7fe363168e3527c7d2080ec052c9ac8de8c1a5f8df7516, 0x78ba4b3e74a10f87158ba2bb555d595570d65a062a3d89c744dc609911f41cc9, 0xd1eb900458634403933ca51a40fc572be7bab53639a91846735f2e6da61adac6, 0xb477711ad7aac0664931bcd260d7d68ac7355bb36cdf23829f55f000eff4add8, 0x525acf38809790e34557bb5743554067642f4840d632299c8a28c48002a97638, 0xcff03e35605f5d638a469ab976cbf73cbc1e29d06839b39e970aef57a98ddcf8, 0x688404b84e3812f9fb87fbd4957f296302200e2ca74ab0175e33bbbd7c6563bc, 0xbc78017abb2aaf403f13e198a4d0175ecda72f740830b32a94a8418aaf8154e9, 0xacad3d13ec936b8ba2b651ac07ec60c607a1e5cc2e63903234e7a6e3ab97ac64, 0xd91e19b0211914ab9ce26849d29cdaf37894615750f6a3e80e2436bbc6e4bd28, 0x0a00d0369e6771a46e63a5d90efb6d214f9522f848aacaff5eff54434071e26b, 0xccb995a884dd08b3b0542a216884826ada70f8191259d7af12212f938a13a23c, 0xdee0498c4773e8cc026cc44d264cb30a2e7ea5497b87d69b64ab854621441e05, 0x46ab2810862b8ca3dc50a93d3705082032a0bd1baffcae4bb6ea19b3efa247b5, 0xd68f9827087e7698785d0976d8e8570ecae664f7d5f88bcdbe50fb90733be4a5, 0x91ee3a3fabcdc21b6619d5841ebb8b999fc6f3f426676d6db41cda95cc436ab0, 0xc5f37299b33de4f75a37e21d037e71b06c214b4b28c57b36be77729637f8bf09, 0xb7f58451e9eb726ba6f37ec10d0a44f5dfc0437fa2e846f09f0a0f6b46429306, 0xcab3f7d5a3c7241d3bf37be65c58925c6496a7354faa0127732df697ffe87dd7, 0xe745c6b675d9cfad5e2af3b7a71a176055411d8d3632126f7190bb84cf96626f, 0x9dd0dee089f296da7334981d4b95f111ad8ed26100396fa43d53ca796a2efeb7, 0x8c7a49d365ac5daba482a7c70e96dd06551732be7b6c7db63f22d3fd579911d7, 0xd2ab8d45f47f1189a1acf2c6ac8c8d1aaaf249eb0ce2ffdd284df6447458f2a2, 0x42afafdba6095414cb29a7249e12b0fbfcecdaec75895bd6b14deba3aff2beec, 0x7a07a784af9f71d1b61fe81d2255b8d33039efcde6dafb5b84b52fd1c02f95a2, 0x81397cc8288e9b1f693be612d4285cb9ac332e2a4e8be60f24744718f088330e, 0x7f58104a994952d53f69c9ebb7343e8801a1e492c96228c3414d60d5da49ae73, 0x3854a1ac2acea614da7b4dad165a5f3a4ff9810c4f4320933fd9ba513e19986e, 0x64e52747ea925f1bd7aae9cc1c67a2ae46f10016d46d589289ef27c3d4d81fd7, 0xda3abc6d1d77399c67812fb0062df81da0dd8554eb1834feb47ae5c712b659dc, 0xf33f010d499178dafe68392dc0396b0519b9678618c87e3f303977c781273ae9, 0xcc79183c5a483a42dc870fdc27d4859d5f78797a3205770e759e2758b4da2fc4, 0x71785c818f67c0f5dda3a4c0980c5a636316636d93bf54719309e10e1cfe9338, 0x9045718b324498d18ba3895c5e3c2bbc7b0e74747c8ed59d4760694ee692f875, 0x88a19ec7ff16272fd73d133c1051d378da041a2f7350df2585ac1a539042cb10, 0xec40eae818a0df05b5c09ab189e7291de970ab285d48f82c513d7594c03b6b03, 0x9787c21439379b772b67b03e6e33f03671a4b3b72162a8614d86014db61f044d, 0x875a0b1f41f9aaa61204de30c245635bc0ad40277c5e0ac661f5e40a16488896, 0xb8c690dd09f656850f4e1f3ac6bb86a01ccdefcfe2c9d7e1c32e188204e22d9c, 0xc63178dcac539cbed0c4ff5902a58c2fd2cbacb6d6bfc9d07b55b324f4f33bfc, 0x883d6f379cce4fc5a94b65fce992abf9d681536d72132eee2db05fda110f37e8, 0xd507c723a2ed34aa3cbb1cdbb55bb0938d02e2c4c965140b93052e3dabf14b71, 0xbe0445af4dd7a8d047236458df1c653a17d1f9b9c62915b7e7c20986a2116e0c, 0x377833a75f42812973e7a07964e852d14edfea349341d21f21e92a1bee50ec26, 0x9269f27398d894f5430d2e3cdceeb600814b18a5384e8f95f67c14933b61a7f9, 0x831ef7c8e54cd90e88c569cd5f78cf84dff88fbd1bc88a34d6019b5da32f09d7, 0x92ccfa7b6f1416587493dcb13446736d812aecf3a5d8bd1168ec3711340a33f2, 0xcec528e0f580d997ca056aa90d4e4f58e869ea6895aba29a2b0c70e132d369c5, 0x529551b437200388d7c2ad2b8e161edd8c786a3402d4e4a4455609c96fe300dd, 0x388b3d67f8d32763f7d54b6922392025b02e44831cf65606a9eebca722a36383, 0x30ea005613ff9c252f5d30b877e7579180054b7670e2b9a6856315a1e178dcff, 0xee2ed7d697ee99b874eac0627ad6d2fdb36a437bd5ff4d89b5935f50fcd558a3, 0x38866b8692677bcd0264b514194a1b59905bf5ef63eb38c02e27b034cd17b844, 0x54c3e1bdb9f9e366b8b5d330a534bed0167cbb54df4dcc83e360d14c596fa3ee, 0xe132615f98e003ff56c1d3b08522f496555e1ffe5c34ec4a09b0664d69909dd9, 0x1359738f0396730b786817f049ecb4ac416ada9af71de8c90399eb0431af63dd, 0xf22c5befcc69dcf32b69e50114ebf639ffdff47df56b1ed49e6b288396f798e4, 0x7142c334f5e37e88efd80c55fe83dd245ea78d2fb7ef7510f1eaea5a5d0e5f35, 0x30291d296d3f7286f40bbde4c9983ce6079e16d1796f39c266caefb14ba9b1d2, 0x8ab55ff697b4dfb78ec31e42518e1a8e9fda422825b5d954a68815678926fa47, 0x808a9073dad7adea9e1ce7e8a9f028d3b88d7b0cb36053a111c9ed3b7c09ceae, 0xf767f751a81073c58f048990bbe605a58d5385c37d7f3902ed832a301fa22df8, 0x18d771352ae14337dc491b6f722524618ef48e85367da35a2c298730246d2906, 0xf5338d75968b3a3d49be44a9fd3cd9fd71e4b3af49b7e8af73e8760bd52bc183, 0x73c007aa1028016bc4ee4414861f089df2493dd9bf0d5d3bd418ed68c29f6f3d, 0xb658e3f7d58108fd0f65702c6a4f3ddc94aa49c8a21cc3ca3301360f4221cb6a, 0x8bf3b8eee77a662ab413f7537e5d47f0e04f2c5a260d23e462c75ca004700107, 0x5af0058aadb6dcd6b946ab8921aee45921c5dc2b7c03b10ced76af90e0e1b734, 0xba96bce37d11a78fa530dcfd0f6eb89225fcd609c2cfab8b179f33283699162f, 0x7ae0c66baad820e7b98603d93721c5dcbb69669a9bfea5978fa241cf08e2c074, 0xf3925c47ad3d2d8c140433a9008e423752c66bcf7732598ee74704bf47fde4ba, 0xa98872f773694a12b5a5c6fadec5f2d737fc9326cca576d10a1e18aeaffcd0c3, 0x729ae424b07e3c0d834d5d8a8a5db71efa5676062ed13baf8a4663a75aabe18c, 0x3473552ee2cd0525a708900ed012dc6530f923654188caf43b6800afd4f8ea39, 0x0d91039cc04d7accaba26fc1daa85a3f3547546bdf0cc1fc89144a88359da9e3, 0xecb8d07d60003b57d2a5ce4fe1e2e8d85bf22160843222e386f9fad479ecdd08, 0xbdc6dfc4059d7b4f7e5f3d75311c02fc659910fcb65194cfb06378ce889b5a5a, 0xb045540cac14e96374111cd381f9e05ae7db8efc3306917f251f0452c9f0740e, 0xdcb9df090b087d8d6c6c5120580dc59a2c4f7aa544dc39f949acdf4e1639b09f, 0x809d6a81c716e87ea22cde0b435106821b1335d47440913504f98084c5b397d3, 0x41cec953eb6fc1967144f8247ec6db943a61fc9e78a611cfc78860ca52de10be, 0x5a3a4457130e3dd41ce422ec975c50f9ed4bcbdf207ae276e0651d1b2561df7d, 0x9469c680bc1c5a3ca7036203333133729c888f595b18be446da19897f4875e21, 0x972da2c275a5b91f48d4f3ff6dbb55d7e3da5b8004e679835d4151f56b04852f, 0x5159a96fdd1e6e4726e16468a44a39fb805123d03839b056815a9264d0b04033, 0x41b9a70dd9108b55ec97b0a68ad83ad144a3fed3fafe7728fc04900531d35cde, 0x37d6b9f32f0b68a30a679218324434d329b721c7092e5281d745fb77887aa7d7, 0x90cb7162a7de0a8972bb892f37fffafb66c2e9cf1bdc45734028c910922d8879, 0x2306a75d569366796dbcf86b41f35d9334483898809dc1f5e70c30a46d9862e6, 0x71f5acfa7fb0bcd0242f1b098aff315eeefa89e62b1050bdb4e1750dae51d9e9, 0x74b25f78bf9acedd65202cd032a1f5f514422f3ba3bdf328175e375ca57c4437, 0x3328be493f5726b00e9e9a4582f1bf44878563de65bd74a069c861cbeeef234a, 0x3956202c355851db13afaccbaff52c1915966f6570be4059de017b167b48460b, 0x403b103c92af2fd3870202a69e360a42d6e9ec2f2646103a3e1488457bc59a1a, 0xa4f5916e4fdb8d15935b7ff836902ee6521f251ffa957fd44346cb2636f5302c, 0x7ce549f49fc5ad0a58ec1e35e1eb6667adcf1005953be4ee9047a99a91a903a1, 0x9a982eea7bcc51f214a2e47725c53b9fb20e5638f883ea4d252dad0cabf46114, 0x306500bfc46476c225cb15f555149e324902fd80d29e0a59df4b7504e1dad39d, 0xf8980a85868457973e2c8da10bc377f20bafb857f2d0a8d4e4d3547fdb295333, 0x0d6328ad415b6a26708b78e9cf164555632e507edcfcb9fdf44ab41b226ede4e, 0x80fdd04dfd55f8c23d0a6cb49ed2d44a8cb542934fa0a43705fdd0fb85b58fa0];
    //     bytes32[172] memory wordsFixed = [bytes32(uint256(171)), 0xfe4a8847f9993068f5d2e3feabb4ed6d22a1ee411ee6fbb86eed7476f82f398d, 0xaefb4fc152ca3a8ad0d9f7d6edc47d440b0e97261d2c955e435cdafcb42dd418, 0xc5e1cfc7d3fb4bc00dbb41fcdfc86f22bec5294aedfd9dfe64f76d9199f6808f, 0x441d812ae23e0edc70651b9002a68eceb1e232a96af4cc7e5aa7bd4a5cdb3982, 0xbea70f91d1addc281e45c89f0422bd16267c61e8929796a1308650b045df6688, 0xe83b99adb42a4bc38a2c546884c59cdb912db7c86074e7b46d5fed14eaffa09d, 0xaea30ca74a329012a4cae2de76bb6e20883fa6cfbe45e000800c02cb3c9d3bab, 0x23c7b46ab42ad661e8ae24e862173d697a2f7179daebb310071ec495c98ad4c6, 0x2446e2921d3d0bbcd9e4bda1aedc528b519fa07d47365ba43802b916620263b6, 0xb428b6304ede79640e405156a71860b26425555e1bc8b0228030c8782ed14e3f, 0x3e012e1b979b858e5d893479df60f155a595b58a349699232b6c2d4203546c9c, 0xea93caaaf9d682e46390634094189db773194bd4e4fe9d073420e56ab6481126, 0xb64b33aa34993e819d440704f7227377ee37cec795ef4042862ad676fdc7e131, 0x7e1f3d27d314f776715db039621dfcea99f18f7507a01b5b6b22ddfc40160328, 0xdb6425924a870047d5f8ece9da55ef7d9e8e81dbcf5721bf64137d6539a617de, 0x31e614542537034d55f57e9c891e2749274fde94d4cd00b36b5f8f20c7c98f2f, 0x1794ab08f86ff2021109357ab6fa9a6d8036be99da29cd4bdcbfde6fe8375526, 0x2e3b2da4ea20f0860def61b1bbc4bdcd5dabed149212ca82493946ce57042142, 0xbcbf5c61854ce57cdcff978417189f3d1731218c31ef21e41e1200419b16f692, 0x9c210773269db174472038f98e94ef51382616bc63f1e9799d68212fa2c42e77, 0xcbbc0ede3300cfab2b08dc123dab21eb7688358a70d09a553130a34956e9988d, 0x84fdd7ecfd91fa9c8007a06355b9ccbb372bc7c84bea8c7410ebd0f75c7e216f, 0x4ea04e40831751e0acf867114cdd6aa26b50182193078d9c6eb1627d4c491f4d, 0x25ef5e2a1409a6b63ac4a5d6a9bedcd7a170f7ee099f5201958c325cd45ecf89, 0xdf49d5801922b1e4aa022c4ea06d5cc0c34ef47657466e0ff9d131a42d61e160, 0xdc157bd95eaedb1ce8d4ff146d8eb0aca6aeec0f110f2b41ee42a3300cef5b3b, 0xbd93ea318ef24eaccb8e7d3ad61d36b71141eec36be6e54c05c0c07167511604, 0xd2dacc7a972ade3ae0540cbb20756334024e7830b448e6814787e69d1e075512, 0xb0a6d63359803146b323657549d37d044945865919b829d8e9ce968078623d7e, 0x2374471d7bfa4936e6e1e9b1aaf3230555a019529d38e7a3606ef46ffceb57f0, 0xb6eb30d24d6a7f954d80ec34cb1393a58c4dfbb047292ad463964f25ec860926, 0x18f285f2b1b93331f111c2639348426981d72bcdd8a47693790d5c4aebe57abf, 0x8155f7f11955ca676ed0cc184b83b1e683c5a97e0f12254071c03a76aa06af38, 0x578c2ae2010cba7eed3d1946a684858373c855d7929553fd52afd0e7a2640ec7, 0x1456d3c0a2b550091142f4274ba8b8584239c25dd8d9d4a8c0ee96036ecfa351, 0xc1518ac7f9f98ebe2c047ef1fb3ec94af801520b5202523a4d99934f3869eccf, 0xf5dff896d50313083f07117fd86824b32d89f63ccbb22cc9480413ffb869b782, 0x4fc6281332de5d08bd874309f87480910a0c3e8bce8e57f874916749257ad5ef, 0xbc6d98f0707316ce7e8f2d068b972f7f82283f0674fc6fc5d78d8f61b9ce6afb, 0xc70ce57b29e37b2dff80b58e657f53df648340ee6b74bdda351428971a56d4b5, 0xfa06370f89eedd64c2e1a47ae91f9ddd2820650f71112149608924342555217b, 0x09dafd6e6adcc3856015564bb8805eade797056dfa2026358a8e789561bb1dbf, 0x256a75ac16c2603eb85ee19e7a13e6726f2b124471db2299dda3d37de4a101db, 0xc50a931c6eda1158998fa3a60e54b6a49c96831fb70ccd5b157c050427821d4b, 0x80fd8bfd3f8c31d434a92966b4e5997453a434aa0ce1e9d9ece185eccda4e186, 0x399e0fdada5abf7d0fd27ab2c720d702c5fdaa5274da696919126d40aac19527, 0x29d79815526f77650c0d904573b25d4764e848e231d7156f789ec24a8f660fa3, 0x9a3ee90166a969bd7a2de9c02fc03c254545e8fc29c4b45bea636ac214f05b53, 0xa72a9c9e806fc4388b4340e2685db0ea0fb15344939fa05a1c87329764e43e64, 0x022625a2e5a06e3649c88a45b27576a4627b2b766b0fa2335bb2b3d8336c97b5, 0xc0314cbd5568412c47f350a052402dc48d453abd7ff083f76e9ce5bf49fe33ec, 0x2c840a5f5404a26b67e25b49d1cf8ebe0f385612d4fd3328696ce860280fa644, 0xd917b22e20b15cea50b724e88857d05d72af3db94c9824fbf0bd4b9bff8e417d, 0xe27dcf46505d3a26c76f5729d0916cc66ab24c58d2009b6b6276b3e9fbfb59b7, 0xf8de0c0f3171d1353741920ca1abc9df53bec215c51215cd3ad2c2f3282b70d4, 0x5238e8cd4a49fe8df7b0134a11fc188dc325d21ecf1aaad521812c89ab66ea9e, 0x0d338c15f633202bf102ec791954b87ddbb4e9abe27efd828b0bed2cb7468998, 0xe8a610c5aec544344b54c4ac4caacd804c22a54489def18a1d02cdde217d4f15, 0x9e2fa6ce7249e88e30ad584bc37727a013a87223751ea39cb4081e2d68e1b2f2, 0xb466779a9ffe58d4c8867852c89cb19f0b3e16b82530856ff88574ebd8fcac0c, 0x1988999393aec3c03bf467c8511d184f9d43fa828d4ec4f0536654718d2bd011, 0xdc5622bbacac2c36873af6d0ab48369125320ca7192f74deea15027b72deb192, 0x7f7c53981d79799acb4ce31cc220e69b07d788fe723d79083ec44b3a7a478cc7, 0x4ffa4f9f8a857b1decf5ca28c47858776eb1a1fc1e09f9d092dfa756a2d0091e, 0xdf51643226baad43aae5a10de875389673df1ab63bab8dc4033cc78773a325e9, 0x9e68adea88830522eb16bd2ce0f1c97ac95c74d00827ad3381fdfc0ff8a6cfca, 0x937fdb7dbf80eea0a2e7ca970f45ae77b68d0a775891e9d845b24ba139d94c09, 0x836c34eaabd62634fc01630507d1255774948d3926a49666b2bb6467dc553884, 0x0b7caa3ddf3cf293359f02b72f9bd2d75bdae554335d502f13ff0a9224ecd99a, 0x03706050f0af4f5f8c3bd2e9e4b5c2c4571244164b105361db1fdc4938f7f15b, 0x583d311ff0b3363470953e5d5f7161c3c2a186aa36960d10196dbc2f5300e499, 0x064fb85f23450c1a6efe6a83c283b9645e6c0d1921de6bcfc90325d3f21604c0, 0xe0043a74f53f0da3dd24ad336e04e39e6554206437755fea2065c5092032b059, 0x9bad6e9c8707a4356ce031cf4141ca30ac9c2d562150ff3193da1a9896fe55e6, 0xb5be609c9bc0913490056578d3239c04a68b86a45eda3f7b33f2db2f289fefca, 0x6fb84a68bdeaf18932898ecaee94855d57c7a4f83bebf48a303167e6b6ea3f75, 0xa3f366ea96dacb830e29065f3347b02ad5f2b2a7ea88fa94eb08ea85976bb008, 0x028230577317e720719d15fa443b5cdb38919f5c0c189792e43712918250bc74, 0xdaa094127d989928ba7cdf6daf6036a7c0933bd5eecc9b9e37a8dd419bdb22d6, 0x358b82f27401506e41f28a82ec7adf4ba2a96fe12d90b3318ed4ee2d94a6723d, 0xcea524abd668c14e1d129b910622445247a0d8b4e59d0128cb0a20540a72a0c2, 0xe37063625c7c1e9536417d9e84f2bd0906dc998752ee53e1f6beba4b6dc3759c, 0x62fea6367591455dd3147929db874399e07e375eaa8f82a2c0f369404caffdce, 0x286f5f72014debe994c34b2801b04055af4de2d78d49d5b013008779ab228cff, 0x77e183082e9c9df59eb086d41d5c5c24bb819d57ced564e02e8146f582b1b8e8, 0xd78588bdbbfb23881d85f9a7bfca8da67ccb7f089b8262e52e76dc3aa49471f8, 0x63a042290899fdb04712d13db184fecc9adf526ea054a4d749df2f2df24fb524, 0x4a27f0fde6bf32d83d06b4755a645ed9c54ee9c0e803778640e983b7672e7557, 0xbb29202f742fc0902797b88dd09ef1f8e646679233b0bacaa89c4e2fe76e1d28, 0x22bbc8057fc81f369be8ca1921bd926c76f73a0ad6862d730a3169e84d4c11d3, 0xe8feb3a94b69ad5d35af48518bdb7947bb877118a45e2515899bbc02fcb88d0d, 0x0a46939bc9efd1ccbf99930b8ff8257183cd02ad6874f787fd3766c99f55ccb3, 0xd9b94f180d522d868fa03ee84623b9f0d378cb4a0329a8e9873afd09903a86bf, 0x64c63ac2a3027dbe061e871dc43dd0eb97ab4daf6b5176a1d4d8b175db3b9eb9, 0x51594432ac15c61436df498a5c0b0e1753c8a12f44fbbe7f33e45972c1492ef4, 0x971f0d919884cd712e40d41ee6b8f3d527aa61cbfe85c42f1b09b23e57baeb33, 0x902a864784dc3522f71dc361c21da5476fee39e1e3bb7ba26d993443178b5113, 0x3fc5c94ef76fa8b5706d74640a53f25c27ce5a0b9640fce874a24d171edd8d4a, 0xc916c0413ae772640bce3252fb75807b6b7733ca4a727fdd64f6c72f12065ce7, 0x6ed6f989699ed4b0cd19ea7a13622936e299353de7afd6aff8feaa03bd486b16, 0xef1a1b46c9c932e535630af3be62bce102afad3155b4af3a8e964c76f04ad8c6, 0xdbbcefb8ee67953615272d7dcbecbd2df1a1008ee6f56fa5c9d0a2861dcae1c6, 0x874e62d2cf93b49120f1e419ec16f602b18a674d2415bfbe0276e85c7c813c6e, 0xe3de8436de17e25fc23faf0bb83e33ba4b66c19693e41ee7d9dfa19ddcedf567, 0xd722373c4d2a8ce7bfff062c928e388c1ffad4696ca3f53e62d0b148bf922d9a, 0xea6a63a79fe7067a374e6b88d5419fcbad7bf0276402b1cfeb0a555bf934e4fb, 0x0417816ffcf10fa78dd190c1ea0a46a37930bbffab334e73159ee621f68ada93, 0x15f1553adfde25abf40bcab0961d1e64e7a457ba3df4cea69e3ee5e34b6d8d23, 0x4cb4b9fa4a3b6283eded436db744f14c0eeb71f19ff12076de807d3388a949fc, 0x8f9d4b1a9d98eb8249d7394168f6a893351cf35e8499dead01b116f1c635f60d, 0xa5f035a9d3bb97be5340921753cb019e70a9ab38aaea0eb91e726555d79bbae6, 0x2d7a334ca6b7d6f47c159767408eaa86ee240cd0d14b13ea3329a7125744d483, 0xc95937e4f8f482feee1f556c972411b97eda7be3105fb9c7ed9117a6279d93df, 0x1d7494dbc15b38486dba55421cc5beaa8092d1da0a9930139dc7fc7daf9fb056, 0x6b4433812c13206cfb8740ed21ec25cb92a8a980fbf7101bad983cc1d2f20389, 0x1d5224657b5e3ef72f9fd5daed833bf1767dd506663115e95a4365e381b1c4f3, 0x0a874b80c1fe548086a8e039cf582f2bb89c31b2a48bfda7c9bb8a4296a272e4, 0x4822571078175ff34dd883192cc1f27740cf6856603c4e9c35d329c61bc5ff5c, 0xf45d4517ea801e4e85179d8f1067ef2ca4792a258107c870b7cc9bbd184323b0, 0xb5cfd6a1b4bf0fbe70d3079735da37e96a48503311f8b9e7df5a8562510d0239, 0xf1f26b26415c1fffca2d95e3855055e77772ee50767c9ad7f8f61f7610a12a4d, 0x972324d956ac03254fa9fe64e543f1c0d9a0deccb1396a10001289fe6a9b745b, 0x1d7e6911a2e8533eecb1b80150bd60c89c752ce03d9f8e3b966d320233286164, 0x6a687f46099f9c88759b7f2d97044d7fbb2d40bbf428c0ac245a5dcab5e41a4f, 0x859e7afbbbaf98997ed6b3491737248c29bed5e0453d2fc2aff0d30641552df0, 0x7fbfb089aa62763687f53c6c4fa521cbebc896ef2509baa9b7eb9032ab67a350, 0xfbd94d39711d301c084344259a7edb6bd4766aa4017e0c68c73f7ab9bb377825, 0x3797d8b67a37542916e5079b6c51149f8de96ebe11fc0d3e8ee60935d15deceb, 0xb6ccd1f4c3dafc6c8a07cc16a75e1c185ed1e680ffbac0bffa2c7d081a385725, 0xca437e59713d9ffb7fea93670ef710054ba72b41d2080e17d2c68c5afaac76eb, 0xf6502bed37490e18575e7caaae9b860cb673dec7bea86be0f16461f209175b94, 0x7b37d56819e695110a6d97e1b45bf3207af18f0e32d7861f3c656eb7df919958, 0xf5207c5e3132b106d0760eadc0d7d78d3e8fbe55d79a9da6eb13281cd0b9c28c, 0x3ecc97de60769e7f30dfdd0ec8b6cc64fdefab3e9c95609ada039fec4f6b6582, 0x950da7208a1579422e9011c44e2d1788bd07d21fba81cc70700be1c08767da66, 0x493408e333a982464c2bafe2b38b9ab956997aa92148ba728e4a898ef097478a, 0xfb05b6ac79651bc9c015af1207d8f4696bc4679d6234f7d0077dd4259cdd60c4, 0x61da9191912bdb5da04f496285edfd010d2031747d1b3bade6d40fc871ea49c6, 0xf74fafea06ad96b21e116b079cbd2fb91607884ecbf222ced976540b33add129, 0x6e35a3a21d82ec43a463d76aa91ea700b4b028f4f471bd51e1a4fcdbe1a9d146, 0xe7074134220c506dc07e5793129eceaf4318d1c24d54100f4ac2deb2bff0c907, 0xfcf3a18403cf3060e865bd15298dcfb37771ebf2c6497f36e20a3a3882aa18d2, 0xa637cfc8a1d6739f5507b0527221cdb7e9990122eee7e54612348eeb36c73449, 0x2de2e4e924c1cec90dcc55bcf04406a3c341af480572cc5f772e30b0a182be55, 0x125a2f33916afdef3e4df463d56638fa222cfd4d7034f52565ed5c836d891f3d, 0xddeee7bc3e4df88c906f5e2c41ae728879698718349691612aa66f7688098dc5, 0x094a51e165e8e8ea1d12693b7f00452ec4f2b4e93c4841f23f40f588ab08367f, 0x524945434c3b9ca8744db23b4392905a6c303d2ee88e258402b24cfbba7d99ed, 0xcaba21a3eb98f435ba4f688e74c541d84ad9e9f7f43df5a76f1aa75ff0597101, 0x94963805655178eb81c7cd352a0f9f2ec37c1ca4d34a905047964eb451a0cf10, 0xe1dbe80285a16fc95561b462bce3c4cde872498654ca6a833575b97db21290a7, 0xc612e66e212c7ac54ffbdcba6960c5ae9fc3b52e01767dfa9fe32a154c8a45e1, 0x2f4d88e9cdff4bd4c5ea70845af716d440cbe0e4d4c5e2c0e6bb9773118fcaff, 0xdb41e470044565a9e150a4996dd39b0e3491a507ecc925dcb802566d14191931, 0x54b85bc7992222d0e0fd8ef901b05d4c6f5121faac2325ec0fd8794a801a0a9e, 0xfb002991bb98e5e294a2ee12fa8bc46f0700f28eb45aa7b1168a8b5434e94089, 0xab3fd8ca0a8c3baaca719cec4d3a9af47f56807d77ab4442f782f487f2a525b5, 0xff943efd7d2ce64664e3725f3b4c600872b43f7dffaea38db5f6cc2f99892694, 0x85439103040bd726014b3098b63ba0057b61fe24bf55ea6b4a19bf8371729d19, 0x1e87bbf32bb48704dbc39d2e658fc0c4dcce2a90b0a26dca2efe61f88a4116ba, 0xe92e65468dbbf48894f670db2a64b1f25b0a1b9574013a54a1be91d381fe63a1, 0x5e5adb8e7de427ab3eaba1db3daef7285f0d3a001b6f689effb4c8fa6cdab1cd, 0xb2f7bef65b53e681b640e3ed77e86226dca27d418444437cfb68dae39b539a58, 0x2ce2742d5919fdaaf77e97b9d6a37c79a872f53f5c118fc41fa109fc923637f1, 0xfeb780bbe1e910dc3da4c1fe304e5a36f30cc7bc0b619ccb654b542139d79d83, 0xe837adb4097a340d3ead309648017a7ee92f579ccc2f4a17d49a53612468891c, 0x843465744f45ccf0f079eeaf2430c9edc8d1eb6035edb8bf77af12dfa201788b, 0x22c2eac3d8a522fe9ece7cc478978e7bae87908919e1dfda005d7150c233dbc7, 0x6ea23fb315b3978808434b0d150bfedeade1768592cc01f03a52e521cebe3f44, 0x34a69ae503b04279308c23664b903c3d24e6a58e6f6694d8c2d8077156124f4a, 0xac83ac576b6c1ef7d79afa922e1a472ddb6c33bcb79ef28295bfde0bb757e257];
    //     bytes32[] memory words;
    //     assembly ("memory-safe") {
    //         words := wordsFixed
    //     }

    //     uint256 j = 1;
    //     bytes32 notFound = 0x3cfc693b595d56c5d2908fbb0135a439ddd5490c4f208fa4bae644d4830ba629;

    //     j %= 171;

    //     bytes memory meta = LibParseMeta.buildMetaExpander(words, expanderDepth(words.length));
    //     console2.logBytes(meta);
    //     // bytes memory meta = hex"023b118d3ba01020abc189f6822b4f4afb519c274f2cee08404f1da1a4f00e4a1ea00200000000040004020110040480840000000001000001000800100000104020020001214ebc0500146e3432070019ff8bf809002da49cf50a00353a0cee0b00600a928d0c00259dbc4d11004fb023c0130054595790160028621ef0190029c6cd6b1a002608af1f1b002b73872c2400036b35b32500480f5b4c26006c4138832700723b317b2a0069f14e252d00391f82542f00330292c8300037556a7035003bd6c9223700498a0ebf38001ba6d1993a0040a8d1893b00451f6a223c002fc66b65400034edd78941007cafd6f3420068d3e6c643003a7d793146003d39b8634e00806c859b53004ad706bf59000457edc65a0053ba5d6a5b0077b9010f5d00363311635e0063b88e2f5f0022308f026200070c73eb63000655d23865001fb45aeb68005b1fbc4869000918ac6d6a00769201d66b000eac4c0b6e0061fdbd8270005241893d71001a0ebe1772004d78597775001763027f7a0059a130187b003870bc8a7c00753d15477f0031a8b0f8800030f68ae48400708cce0686001d755af788004e8e975989000d2a5c4b8b007f5f44608c007ee897828d0043701d648e005647558c8f003ca340f6910011699e13930015297aaf960044f1f2cb9800126608ea9900100e5e909a004c60878d9b000aec1d059e0062389c69a0005e9e3809a1006bd3e94ba30023784971a50055c3c728a9005c970534af003e35b200b10005d89b57b20027158727b4002c0d77c7b5002a13264cb60067c6a076b7002e862d12b8003fc34adebb00788ee024bf0032e7d8dec00020ce9646c60024c84147c7007deed4efc800021dba89c9004796325acb00004a0316cd001e44dceacf005111d59ed500664f6bdbdc005d0d33d6e50013f2ddf9e7005006b4d7e8000bd79fc4e9004b43cddceb000f052f3fec005fb10893ed00216c5ebcf0006d1e5395f2000ca06ce8f3006e425f2ff7004234a83df8006f867690fc0041cce87f01005a0784040d00738119191600748770e71c0065a36db4340018cf4dc0430057352a4a5000469e44c2680058098258920071bcd9ed97007af35ddd9f00643e0037a2001c6add3aaa00163d6a01b4007b724ae9b8007911e5bcc100085bd933ca006a107fb6da";
    //     // (bool exists, uint256 k) = LibParseMeta.lookupIndexMetaExpander(meta, 0x7ce549f49fc5ad0a58ec1e35e1eb6667adcf1005953be4ee9047a99a91a903a1);
    //     // // assertTrue(exists);
    //     // // assertEq(j, k);

    //     // // (bool notExists, uint256 l) = LibParseMeta.lookupIndexMetaExpander(meta, notFound);
    //     // // assertTrue(!notExists);
    //     // // assertEq(0, l);
    // }
}
