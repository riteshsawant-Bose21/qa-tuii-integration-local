#pragma once
#ifndef ORTHOGONAL_H
#define ORTHOGONAL_H
namespace bosepro::math
{
    // Wanted to put this in GeometryTools.h but that led to circular dependency where Segment/Plane needs it but GeometryTools needs Segment.
    // So put into this separate file instead.
    static Vec3 getOrthogonalToDirection(Vec3 direction, bool dirIsEdge = false)
    {
        // ==================================================================================================
        // dirIsEdge = false, one would see direction vector spanning the face of a plane (up or down)
        //                    another way of viewing?  90 deg rotation would be on azimuth, Z rather than pitch.
        // ==================================================================================================

        // A plane would see the ray across it (either up or down)
        // Example 1: XZ plane from ray's X direction vector, the resulting orthogonal direction vector is on -Y
        // Z                                  Z____/___
        // |                                  |   .   |
        // ---------> X <1,0,0>               |  /    |
        //              dir. vector           |_/_____|X
        //                                     / -Y <0,-1,0> result orthogonal direction vector
        //
        // Start with <1,0,0> direction vector. Azimuth (about z) is 0 and inclination is 90. Nothing to back out on azimuth.
        // Back out inclination to change direction to <0,0,1>
        // Create orthogonal by rotating 90 degrees on x for a direction of <0,-1,0>.
        // Reapply inclination on Y to leave direction unchanged, azimuth was 0, so final result is <0,-1,0>

        // Reversing to get left/right direction vector on XZ plane                                            
        // Z____/___              result plane dir. Z                                 
        // |   .   |                    -X <-1,0,0> |        can give left/right bounds for rectangle on plane
        // |  /    |                      <--------------> 
        // |_/_____|X                               |                  
        //  / -Y <0,-1,0> orth dir.                                        
        // 
        // Start with plane's normal, <0,-1,0> orthogonal direction. Azimuth is 270 and inclination is 90.
        // Back out azimuth to change direction to <1,0,0>, then inclination to yield <0,0,1>
        // Get a direction coincident with the plane by rotating 90 degrees on X for a direction of <0,-1,0>. 
        // Reapply inclination to leave direction unchanged, and apply azimuth to change direction to <-1,0,0>.

        // ==================================================================================================
        // dirIsEdge = true,  no dif b/n resulting plane and direction vector provided. Appears as line.
        //                    another way of viewing is that 90 deg rotation is on pitch rather than azimuth/z
        // ==================================================================================================

        // Example 2: XY plane from X direction vector, the resulting direction vector is on +/-Z
        //                                     Z 
        // Z                                Y__|_____
        // |                                /  |    /
        // ---------> X <1,0,0>            /___-___/X
        //                                     |-Z <0,0,-1>
        //
        // Start with <1,0,0> direction. Azimuth is 0, inclination is 90.  
        // Back out inclination to change direction to <0,0,1>.  Direction doesn't change for azimuth.
        // Create orthogonal direction by rotating 90 degrees on Y for a direction of <1,0,0>.
        // Reapply inclination to change direction to <0,0,-1>.  Azimuth doesn't change.
        // So to have horizontal orthogonal rotate 90 degrees on Y
        //
        // Reversing to get left/right direction vector on XY horizontal plane
        //     Z 
        //  Y__|_____                             Z     
        //  /  |    /                 -X <-1,0,0> |     
        // /___-___/X                   <-------------->   can give left/right bounds for a rectangle on plane
        //     |-Z <0,0,-1>                       |     
        //
        // Start with plane's normal, <0,0,-1> orthogonal direction. Azimuth is 0, inclination is 180. 
        // Don't change azimuth since it was 0. Back out inclination to change direction to <0,0,1>. 
        // Get a direction coincident with the plane by rotating 90 degrees on Y for a direction of <1,0,0>.
        // Reapply inclination to change direction to <-1,0,0>.  Azimuth doesn't change.

        // Example 3: Reversing to get up/down direction vector on XZ plane from example 1.
        // Z____/___                     
        // |   .   |                      Z
        // |  /    |                      |------------> X
        // |_/_____|X                     |
        //  / -Y <0,-1,0>                 | -Z <0,0,-1>  can give top/bottom bounds for a rectangle on plane
        //                                            
        // Start with plane's normal, <0,-1,0> orthogonal direction. Azimuth is 270 and inclination is 90.
        // Back out azimuth to change direction to <1,0,0> then inclination to change to <0,0,1>.
        // Get a direction coincident with the plane by rotating 90 degrees on Y for a direction of <1,0,0>.
        // Reapply inclination to change direction to <0,0,-1> and then azimuth to get <0,0,-1>.

        // Example #4: YZ from Z direction vector, the resulting vector is on +/- X
        // Z <0,0,1>                         /|
        // |                               Z/ |  Y
        // -------> X                      /| | /
        //                                / | |/
        //                               |  | /
        //                               | .|--------> X <1,0,0>
        //                               | /                    
        //                               |/
        // Start with ray's <0,0,1> direction vector. There is no azimuth or inclination to consider.
        // Create orthogonal direction by rotating 90 deg on Y for a final direction of <1,0,0>.
        //
        // Reversing to get up/down direction vector on YZ vertical plane
        //         /|
        //       Z/ |  Y                     Z
        //       /| | /                      |------------> X
        //      / | |/                       |
        //     |  | /                        | -Z <0,0,-1>  can give top/bottom bounds for a rectangle on plane
        //     | .|--------> X <1,0,0>
        //     | /                    
        //     |/
        // Start with plane's normal, <1,0,0> orthogonal direction. Azimuth is 0, inclination is 90.  
        // Azimuth doesn't change, backout inclination to change direction to <0,0,1>.
        // Get a direction coincident with the plane by rotating 90 degrees on Y for a direction of <1,0,0>.
        // Reapply inclination to change direction to <0,0,-1>. Azimuth doesn't change.


        Vec3 oDir{};
        double r = 0.0;
        std::optional<Angle> azimuthOpt;
        std::optional<Angle> inclinationOpt;
        // Get the Spherical coordinates (r,azimuth,inclination) from the direction vector.
        // I believe we follow U,E,N for Z,X,Y respectively. see: §Conventions: https://en.wikipedia.org/wiki/Spherical_coordinate_system
        // But to avoid confusion, will use the terms azimuth and inclination (rather than theta/phi) as domains can use either theta or phi for azimuth
        // NOTE: this was done prior to having x-axis flag for elevation rather than inclination. so here 0 degrees inclination is pointing up positive Z.
        if (direction.directionToSphericalCoordinates(r, azimuthOpt, inclinationOpt) && azimuthOpt && inclinationOpt)
        {
            // We backout azimuth to remove any Z rotation which will place inclination on the Y axis which we can then back out. 
            // We do this in order to make a perpendicular rotation that results in a direction perpendicular to the original direction once the angles are reapplied.
            // That perpendicular rotation is according to how one wants the orthogonal direction to the supplied direction vector (on edge or face).
            // Since there are an infinite number of planes about a ray in 360 degrees, we pick those 2 from the observer.
            // After backing out angles the direction is pointed at Z and then rotated 90 degrees on X or Y depending on if one wants facing or edge.

            // Really we could do a rotate on X 90 degrees first and then an arbitrary amount on Z (if 90 degrees same as case of just rotating 90 degrees on Y).
            // Reverse is also true of rotate on Y 90 degrees first then an arbitrary amount on Z.

            // create matrices for backing out the angles and apply them
            auto& azimuth = *azimuthOpt;
            auto& inclination = *inclinationOpt;
            auto mat4BackoutAzimuthZ = math::isApproximatelyZero(azimuth.degrees()) ? Mat4() : Mat4::rotation(0, 0, -azimuth);
            auto backDir = mat4BackoutAzimuthZ * direction;
            auto mat4BackoutInclinationY = math::isApproximatelyZero(inclination.degrees()) ? Mat4() : Mat4::rotation(0, -inclination, 0);
            backDir = (mat4BackoutInclinationY * backDir).normalized(); // now we are oriented <0,0,1> regardless of input direction.

            if (dirIsEdge) // resulting orthogonal will create plane that appears as a line (viewed from edge) assuming observer is at -Y with X to right and Z up.
            {
                auto mat4RotateOnY = Mat4::rotation(0.0, Angle(90.0, Angle::Units::Degrees), 0.0);
                oDir = (mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * mat4RotateOnY * backDir).normalized();
            }
            else // apply rotation (and reapply angles) to get us an orthogonal that will create a plane spanning the provided dir vector
            {
                auto mat4RotateOnX = Mat4::rotation(Angle(90.0, Angle::Units::Degrees), 0.0, 0.0);
                oDir = (mat4BackoutAzimuthZ.inverse() * mat4BackoutInclinationY.inverse() * mat4RotateOnX * backDir).normalized();
            }
        }
        return oDir;
    }
}

#endif
