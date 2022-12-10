import UIKit

var greeting = "Hello, playground"

func degreesToRadians(_ x: Double) -> Double
{
    return (M_PI * (x) / 180.0)
}

let degrees = 60.0

let EARTH_EQUATORIAL_RADIUS = 6378137.0
let WGS84_CONSTANT = 0.99664719
let tanDegrees = tan(degreesToRadians(degrees));
let beta =  tanDegrees * WGS84_CONSTANT;

let lengthOfDegree = cos(atan(beta)) * EARTH_EQUATORIAL_RADIUS * M_PI / 180.0


