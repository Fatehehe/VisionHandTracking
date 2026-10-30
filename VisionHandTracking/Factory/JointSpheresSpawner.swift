//
//  JointSpheresSpawner.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit
import UIKit

/// Factory responsible for procedural generation and configuration of the Joint Spheres Hand Representation.
/// Generates 27 joint spheres with spatial materials and dynamic bone connection cylinders.
public struct JointSpheresSpawner {
    
    /// Spawns a complete Joint Spheres representation root for the specified hand chirality.
    public static func spawnJointSpheres(chirality: HandAnchor.Chirality) -> Entity {
        let root = Entity()
        root.name = "\(chirality == .left ? "Left" : "Right")JointSpheresRoot"
        
        // 1. Prepare visual materials
        let tipMaterial = makeTipMaterial()
        let knuckleMaterial = makeKnuckleMaterial()
        let intermediateMaterial = makeIntermediateMaterial()
        let wristMaterial = makeWristMaterial()
        let boneMaterial = makeBoneMaterial()
        
        // Base mesh resources (shared across instances for high rendering efficiency)
        let tipSphereMesh = MeshResource.generateSphere(radius: 0.0075)
        let intermediateSphereMesh = MeshResource.generateSphere(radius: 0.0055)
        let knuckleSphereMesh = MeshResource.generateSphere(radius: 0.0065)
        let wristSphereMesh = MeshResource.generateSphere(radius: 0.009)
        let forearmSphereMesh = MeshResource.generateSphere(radius: 0.011)
        
        // 2. Generate Joint Sphere Entities
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
            
            // Attach joint identification component
            jointEntity.components.set(HandJointEntityComponent(
                jointName: jointName,
                finger: finger,
                bone: bone,
                isTip: isTip
            ))
            
            // If this joint is a fingertip, attach snapping state component
            if isTip {
                jointEntity.components.set(FingertipSnapComponent(
                    chirality: chirality,
                    jointName: jointName,
                    finger: finger
                ))
            }
            
            root.addChild(jointEntity)
        }
        
        // 3. Generate Bone Connector Cylinders
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
    
    // MARK: - Material Generators
    
    public static func makeTipMaterial(isSnapped: Bool = false) -> Material {
        var mat = PhysicallyBasedMaterial()
        if isSnapped {
            // Glowing emerald / gold accent when magnetically locked on surface
            mat.baseColor = .init(tint: UIColor(red: 0.1, green: 0.95, blue: 0.65, alpha: 0.95))
            mat.roughness = 0.1
            mat.metallic = 0.9
            mat.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.95, blue: 0.65, alpha: 0.7))
        } else {
            // Futuristic spatial cyan glass
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
