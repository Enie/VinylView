import SwiftUI
import simd

struct Tick {
    var position: CGPoint
    var angle: Angle
}

func roundedRectTickCoordinates(count n:Int, in rect:CGRect, cornerRadius: CGFloat) -> [Tick] {
    let width = rect.size.width
    let height = rect.size.height
    let radiusH = width/2
    let radiusV = height/2
    
    let cornerCenterH = radiusH - cornerRadius
    let cornerCenterV = radiusV - cornerRadius
    
    return Array(0..<n).map { i in
        let angle = Angle(degrees: 360.0/Double(n)*Double(i))
        
        let d = simd_double2(x: cos(angle.radians), y: sin(angle.radians))
        let a = simd_double2(x: abs(d.x), y: abs(d.y))
        
        var s:simd_double2 = simd_double2(0, 0)
        if a.x * radiusV > a.y * radiusH {
            s.x = d.x.sign == .plus ? radiusH : -radiusH
            s.y = d.y.sign == .plus ? radiusH * a.y / a.x : -radiusH * a.y / a.x
        } else {
            s.x = d.x.sign == .plus ? radiusV * a.x / a.y : -radiusV * a.x / a.y
            s.y = d.y.sign == .plus ? radiusV : -radiusV
        }
        // part 2: set x and y on the square
        var x:CGFloat = 0
        var y:CGFloat = 0
        // if position on square is where a corner radius should be, replace x and y with position on corner radius
        if abs(s.x) > cornerCenterH && abs(s.y) > cornerCenterV {
            // get vector from corner radius center to point on square
            let cornerD = simd_double2(s.x < 0 ? s.x-(-cornerCenterH) : s.x-(cornerCenterH), s.y < 0 ? s.y-(-cornerCenterV) : s.y-(cornerCenterV))
            // get the angle of that vector
            let cornerAngle = atan2(cornerD.y, cornerD.x)
            // point on corner radius
            let corner = simd_double2(cos(cornerAngle)*cornerRadius, sin(cornerAngle)*cornerRadius)
            if s.x > 0 {
                x = cornerCenterH + corner.x
            } else {
                x = -cornerCenterH + corner.x
            }
            if s.y > 0 {
                y = cornerCenterV + corner.y
            } else {
                y = -cornerCenterV + corner.y
            }
        } else {
            x = s.x
            y = s.y
        }
        // shift by center coordinates
        return Tick(position: CGPoint(x:x+radiusH, y:y+radiusV), angle: Angle(degrees: angle.degrees+90))
    }
}

struct RoundedRect: View {
    var samples: Int = 60
    var rect: CGRect = CGRect(x: 0, y: 0, width: 200, height: 200)
    var cornerRadius: CGFloat = 30
    
    var body: some View {
        return VStack {
            ZStack {
                ForEach(roundedRectTickCoordinates(count: samples, in: rect, cornerRadius: cornerRadius), id: \.angle) {tick in
                    Rectangle()
                        .rotationEffect(tick.angle)
                        .frame(width: 4, height: 10)
                        .position(x: tick.position.x, y: tick.position.y)
                    
                    
                }
            }
            .frame(width: rect.size.width, height: rect.size.height)
            .padding()
        }
    }
}

fileprivate struct Preview: View {
    @State var samples: CGFloat = 60
    @State var radius: CGFloat = 20
    @State var width: CGFloat = 200
    @State var height: CGFloat = 200
    var body: some View {
        VStack(spacing: 0) {
            RoundedRect(samples: Int(samples), rect: CGRect(origin: .zero, size: CGSize(width: width, height: height)), cornerRadius: radius)
                .padding()
            Spacer()
            Group {
                Slider(value: $samples, in: 4...100, minimumValueLabel: Text("4"), maximumValueLabel: Text("100")) {
                    Text("samples:")
                }
                Slider(value: $radius, in: 0...(min(width,height)/2), minimumValueLabel: Text("0"), maximumValueLabel: Text("\(Int(min(width,height)/2))")) {
                    Text("corner radius:")
                }
                Slider(value: $width, in: 10...200, minimumValueLabel: Text("0"), maximumValueLabel: Text("200")) {
                    Text("width:")
                }
                Slider(value: $height, in: 10...200, minimumValueLabel: Text("0"), maximumValueLabel: Text("200")) {
                    Text("height:")
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

struct RoundedRect_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
}

//struct Squirkle: View {
//    var radius: CGFloat = 100
//    @State var roundness: CGFloat = 0
//
//    func squirkleTick(atAngle angle: Angle) -> some View {
//        let dx = cos(angle.radians)*radius
//        let dy = sin(angle.radians)*radius
//        let squareCutLength =
//        (angle.degrees > 45 && angle.degrees < 135) ||
//        (angle.degrees > 225 && angle.degrees < 315)
//        ? sqrt(dx*dx+radius*radius) : sqrt(dy*dy+radius*radius)
//        let diff = squareCutLength - radius
//        let size = 2 * (radius + diff*(1.0-roundness))
//        return HStack(spacing:0) {
//            Spacer().frame(width: size)
//            Rectangle()
//                .fill(Color(white: 0.9))
//                .frame(width: 0.05*size, height: 0.005*size)
//        }
//    }
//
//    var body: some View {
//        let tickCount = 60
//        return VStack {
//            ZStack {
//                ForEach(0..<tickCount, id: \.self) {i in
//                    squirkleTick(atAngle:Angle(degrees: 360.0/Double(tickCount)*Double(i)))
//                        .rotationEffect(Angle(degrees: 360.0/Double(tickCount)*Double(i)))
//                }
//            }
//            .frame(width: radius*2, height: radius*2)
//            .padding()
//        }
//    }
//}
//
//struct Squirkle_Previews: PreviewProvider {
//    static var previews: some View {
//        Squirkle(roundness: 0.75)
//    }
//}
