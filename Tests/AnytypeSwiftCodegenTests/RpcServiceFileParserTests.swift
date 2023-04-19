import Foundation
@testable import AnytypeSwiftCodegen
import XCTest

final class ServiceGeneratorTests: XCTestCase {
    
    private let parser = ServiceParser()
    
    func test_parser_with_different_spaces() {
        
        let input = """
        syntax = "proto3";
        package anytype;
        option go_package = "service";

        import "pb/protos/commands.proto";
        import "pb/protos/events.proto";

        service ClientCommands {
            rpc AppGetVersion(anytype.Rpc.App.GetVersion.Request)returns(anytype.Rpc.App.GetVersion.Response);
            rpc AppSetDeviceState (anytype.Rpc.App.SetDeviceState.Request)returns(anytype.Rpc.App.SetDeviceState.Response);
            rpc AppShutdown (anytype.Rpc.App.Shutdown.Request) returns(anytype.Rpc.App.Shutdown.Response);
        
            rpcBlockDataviewViewSetPosition(anytype.Rpc.BlockDataview.View.SetPosition.Request) returns (anytype.Rpc.BlockDataview.View.SetPosition.Response);

            // Wallet
            // ***
            rpc WalletCreate     (anytype.Rpc.Wallet.Create.Request)returns (anytype.Rpc.Wallet.Create.Response);
            rpc WalletConvert(anytype.Rpc.Wallet.Convert.Request)returns     (anytype.Rpc.Wallet.Convert.Response);
        }
        """
    
        let result = try? parser.parse(serviceProto: input)
        
        let expectedResult = Service(name: "ClientCommands", rpc: [
            Rpc(
                name: "AppGetVersion",
                request: "anytype.Rpc.App.GetVersion.Request",
                response: "anytype.Rpc.App.GetVersion.Response"
            ),
            Rpc(
                name: "AppSetDeviceState",
                request: "anytype.Rpc.App.SetDeviceState.Request",
                response: "anytype.Rpc.App.SetDeviceState.Response"
            ),
            Rpc(
                name: "AppShutdown",
                request: "anytype.Rpc.App.Shutdown.Request",
                response: "anytype.Rpc.App.Shutdown.Response"
            ),
            Rpc(
                name: "BlockDataviewViewSetPosition",
                request: "anytype.Rpc.BlockDataview.View.SetPosition.Request",
                response: "anytype.Rpc.BlockDataview.View.SetPosition.Response"
            ),
            Rpc(
                name: "WalletCreate",
                request: "anytype.Rpc.Wallet.Create.Request",
                response: "anytype.Rpc.Wallet.Create.Response"
            ),
            Rpc(
                name: "WalletConvert",
                request: "anytype.Rpc.Wallet.Convert.Request",
                response: "anytype.Rpc.Wallet.Convert.Response"
            )
        ])
    
        XCTAssertEqual(result, expectedResult)
    }
}

