//
//  File.swift
//  
//
//  Created by Dmitry Lobanov on 15.02.2021.
//

import Foundation
import SwiftSyntax

public struct AccessLevelScope {
    private var kind: TokenKind = .internalKeyword
    private init(kind: TokenKind) {
        self.kind = kind
    }
    static var internalScope: Self = .init(kind: .internalKeyword)
    static var publicScope: Self = .init(kind: .publicKeyword)
    var scope: TokenKind { self.kind }
    public var isPublic: Bool { self.kind == .publicKeyword }
    public var isInternal: Bool { self.kind == .internalKeyword }
}


//public extension Outer.Fruit.Apple {
//    private struct Invocation {
//        static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitApple(data) }
//    }
//    
//    public
//    enum Service {
//        public typealias RequestParameters = Request
//        private static func request(_ parameters: RequestParameters) -> Request {
//            parameters
//        }
//        public static func invoke(name: String, seedCount: Int, queue: DispatchQueue? = nil) -> Future<Response, Error> {
//            self.invoke(parameters: .init(name: name, seedCount: seedCount), on: queue)
//        }
//        public static func invoke(name: String, seedCount: Int) -> Result<Response, Error> {
//            self.result(.init(name: name, seedCount: seedCount))
//        }
//        
//    }
//}

//public extension Outer.Fruit.Raspberry {
//    private struct Invocation {
//        static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitRaspberry(data) }
//    }
//
//    public
//    enum Service {
//        public typealias RequestParameters = Request
//        private static func request(_ parameters: RequestParameters) -> Request {
//            parameters
//        }
//        public static func invoke(name: String, seed: String, queue: DispatchQueue? = nil) -> Future<Response, Error> {
//            self.invoke(parameters: .init(name: name, seed: seed), on: queue)
//        }
//        public static func invoke(name: String, seed: String) -> Result<Response, Error> {
//            self.result(.init(name: name, seed: seed))
//        }
//
//    }
//}
