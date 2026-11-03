//
//  HandSpawner.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 30/10/26.
//

import RealityKit
import Foundation
import ARKit
import UIKit

public struct HandSpawner{
    public static func loadScene() async -> Entity?{
        do {
            if let url = Bundle.main.url(forResource: "world", withExtension: "reality") {
                let scene = try await Entity(contentsOf: url)
                return scene
            }
            let scene = try await Entity(named: "world", in: Bundle.main)
            return scene
        } catch {
            print("[HandSpawner] Failed to load 'world.reality': \(error.localizedDescription)")
            return nil
        }
    }
    
    public static func spawnGlove(
        from scene: Entity,
        chirality: HandAnchor.Chirality,
        scale: SIMD3<Float> = .one
    )-> (root: Entity, skinnedModel: ModelEntity?)?{
        let entityName = (chirality == .right) ? "RightGlove" : "LeftGlove"
        
        guard let gloveNode = scene.findEntity(named: entityName) else {
            print("[GloveSpawner] Entity '\(entityName)' not found in scene.")
            return nil
        }
        gloveNode.removeFromParent()
        
        gloveNode.position = .zero
        gloveNode.orientation = simd_quatf(real: 1, imag: .zero)
        gloveNode.scale = scale
        
        let skinnedModel = findSkinnedModel(in: gloveNode)
        return (root: gloveNode, skinnedModel: skinnedModel)
    }
    
    public static func spawnJointSpheres(chirality: HandAnchor.Chirality) -> Entity {
        let root = Entity()
        root.name = "\(chirality == .left ? "Left" : "Right")JointSpheresRoot"
        
        let tipMaterial = makeTipMaterial()
        let knuckleMaterial = makeKnuckleMaterial()
        let intermediateMaterial = makeIntermediateMaterial()
        let wristMaterial = makeWristMaterial()
        let boneMaterial = makeBoneMaterial()
        
        let tipSphereMesh = MeshResource.generateSphere(radius: 0.0075)
        let intermediateSphereMesh = MeshResource.generateSphere(radius: 0.0055)
        let knuckleSphereMesh = MeshResource.generateSphere(radius: 0.0065)
        let wristSphereMesh = MeshResource.generateSphere(radius: 0.009)
        let forearmSphereMesh = MeshResource.generateSphere(radius: 0.011)
        
        for (jointName, finger, bone) in Hand.joints {
            let mesh: MeshResource
            let material: Material
            let isTip = Hand.isFingertip(jointName)
            
            switch bone {
            case .tip:
                mesh = tipSphereMesh
                material = tipMaterial
            case .knuckle, .metacarpal:
                mesh = knuckleSphereMesh
                material = knuckleMaterial
            case .intermediateBase, .intermediateTip:
                mesh = intermediateSphereMesh
                material = intermediateMaterial
            case .wrist:
                mesh = wristSphereMesh
                material = wristMaterial
            case .arm:
                mesh = forearmSphereMesh
                material = wristMaterial
            }
            
            let jointEntity = ModelEntity(mesh: mesh, materials: [material])
            jointEntity.name = "Joint_\(jointName.description)"
            
            jointEntity.components.set(HandJointEntityComponent(
                jointName: jointName,
                finger: finger,
                bone: bone,
                isTip: isTip
            ))
            
            if isTip {
                jointEntity.enableLocalAxis(length: 0.025, thickness: 0.001, category: .fingertips)
            } else {
                jointEntity.enableLocalAxis(length: 0.018, thickness: 0.0008, category: .joints)
            }
            
            root.addChild(jointEntity)
        }
        
        let cylinderUnitMesh = MeshResource.generateCylinder(height: 1.0, radius: 0.0028)
        
        for connection in Hand.boneConnections {
            let boneEntity = ModelEntity(mesh: cylinderUnitMesh, materials: [boneMaterial])
            boneEntity.name = "Bone_\(connection.from.description)_\(connection.to.description)"
            
            boneEntity.components.set(BoneConnectorComponent(
                fromJoint: connection.from,
                toJoint: connection.to
            ))
            
            root.addChild(boneEntity)
        }
        
        return root
    }
    
    public static func findSkinnedModel(in root: Entity) -> ModelEntity? {
        var queue: [Entity] = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let model = current as? ModelEntity, !model.jointNames.isEmpty {
                return model
            }
            queue.append(contentsOf: current.children)
        }
        return nil
    }
}


extension HandSpawner {
    public static func makeTipMaterial(isSnapped: Bool = false) -> Material {
        var mat = PhysicallyBasedMaterial()
        if isSnapped {
            mat.baseColor = .init(tint: UIColor(red: 0.1, green: 0.95, blue: 0.65, alpha: 0.95))
            mat.roughness = 0.1
            mat.metallic = 0.9
            mat.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.95, blue: 0.65, alpha: 0.7))
        } else {
            mat.baseColor = .init(tint: UIColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 0.92))
            mat.roughness = 0.15
            mat.metallic = 0.8
            mat.emissiveColor = .init(color: UIColor(red: 0.0, green: 0.6, blue: 0.9, alpha: 0.3))
        }
        return mat
    }
    
    private static func makeKnuckleMaterial() -> Material {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(white: 0.92, alpha: 0.85))
        mat.roughness = 0.3
        mat.metallic = 0.6
        return mat
    }
    
    private static func makeIntermediateMaterial() -> Material {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(white: 0.85, alpha: 0.8))
        mat.roughness = 0.35
        mat.metallic = 0.5
        return mat
    }
    
    private static func makeWristMaterial() -> Material {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.7, green: 0.75, blue: 0.85, alpha: 0.9))
        mat.roughness = 0.25
        mat.metallic = 0.8
        return mat
    }
    
    private static func makeBoneMaterial() -> Material {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(white: 0.95, alpha: 0.55))
        mat.roughness = 0.4
        mat.metallic = 0.3
        mat.blending = .transparent(opacity: .init(floatLiteral: 0.6))
        return mat
    }
}
