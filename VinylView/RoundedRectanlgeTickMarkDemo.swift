import SwiftUI
import simd

//
//struct Content: View {
//
//    @State private var tickMarks: CGFloat = 8.0
//    @State private var cornerRadius: CGFloat = 0.0
//    @State private var tickMarkWidth: CGFloat = 16.0
//    @State private var tickMarkHeight: CGFloat = 64.0
//
//    var body: some View {
//        VStack(spacing: .zero) {
//
//            RoundedRectangleTickMarkView(tickMarks: Int(self.tickMarks),
//                                         cornerRadius: self.cornerRadius,
//                                         tickMarkWidth: self.tickMarkWidth,
//                                         tickMarkHeight: self.tickMarkHeight)
//
//            VStack(spacing: .zero) {
//                Slider(value: self.$tickMarks, in: 0.0...12.0, step: 2.0, label: { Text("tickMarks") })
//                Slider(value: self.$cornerRadius, in: 0.0...128.0, label: { Text("cornerRadius") })
//                Slider(value: self.$tickMarkWidth, in: 2.0...16.0, label: { Text("tickMarkWidth") })
//                Slider(value: self.$tickMarkHeight, in: 2.0...256.0, label: { Text("tickMarkHeight") })
//            }
//            .padding(12.0)
//
//        }
//    }
//
//}



struct RoundedRectangleTickMarkView: View {
    
    
    let tickMarks: Int
    let cornerRadius: CGFloat
    let tickMarkWidth: CGFloat
    let tickMarkHeight: CGFloat
    
    init(tickMarks: Int,
         cornerRadius: CGFloat,
         tickMarkWidth: CGFloat,
         tickMarkHeight: CGFloat) {
        
        self.tickMarks = tickMarks
        self.cornerRadius = cornerRadius
        self.tickMarkWidth = tickMarkWidth
        self.tickMarkHeight = tickMarkHeight
        
    }
    
    
    var body: some View {
        return ZStack {
            GeometryReader {
                geoProxy in
                
                let coordinates = self.coordinates(for: self.tickMarks,
                                                   in: CGRect(origin: .zero, size: geoProxy.size),
                                                   cornerRadius: self.cornerRadius)
                
                ForEach(coordinates, id: \.angle) {
                    tickMark in
                    
                    RoundedRectangle(cornerRadius: 0.0, style: .continuous)
                        .frame(width: self.tickMarkWidth, height: self.tickMarkHeight)
                        .rotationEffect(tickMark.angle)
                        .position(x: tickMark.position.x, y: tickMark.position.y)
                        .foregroundColor(Color(red: tickMark.angle.degrees/360, green: 0, blue: 1).opacity(0.75))
                    
                    Circle()
                        .strokeBorder(lineWidth: 2.0)
                        .frame(width: min(self.tickMarkWidth, self.tickMarkHeight), height: min(self.tickMarkWidth, self.tickMarkHeight))
                        .position(x: tickMark.position.x, y: tickMark.position.y)
                        .foregroundColor(Color.black.opacity(0.75))
                    
                }
                
            }
        }
        .frame(width: 256.0, height: 256.0)
        .background {
            ZStack {
                
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .foregroundColor(Color.white)
                
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .strokeBorder(lineWidth: 2.0)
                    .foregroundColor(Color.black.opacity(0.25))
                
            }
        }
        .mask {
            RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
        }
        .padding(128.0)
    }
    
    
    struct TickMarkCoordinate {
        let position: CGPoint
        let angle: Angle
    }
    
    
    private func coordinates(for tickMarkCount: Int,
                             in rect: CGRect,
                             cornerRadius: CGFloat) -> [TickMarkCoordinate] {
        
        let radiusH = rect.size.width / 2.0
        let radiusV = rect.size.height / 2.0
        
        let cornerCenterH = radiusH - cornerRadius
        let cornerCenterV = radiusV - cornerRadius
        
        return Array(0..<tickMarkCount).map {
            tickMark in
            
            let angle = Angle(degrees: 360.0 / Double(tickMarkCount) * Double(tickMark) - 90)
            
            let d = simd_double2(x: cos(angle.radians), y: sin(angle.radians))
            let a = simd_double2(x: abs(d.x), y: abs(d.y))
            
            var s: simd_double2 = simd_double2(0.0, 0.0)
            
            if a.x * radiusV > a.y * radiusH {
                s.x = d.x.sign == .plus ? radiusH : -radiusH
                s.y = d.y.sign == .plus ? radiusH * a.y / a.x : -radiusH * a.y / a.x
            } else {
                s.x = d.x.sign == .plus ? radiusV * a.x / a.y : -radiusV * a.x / a.y
                s.y = d.y.sign == .plus ? radiusV : -radiusV
            }
            
            // part 2: set x and y on the square
            var x: CGFloat = 0.0
            var y: CGFloat = 0.0
            
            // if position on square is where a corner radius should be, replace x and y with position on corner radius
            if abs(s.x) > cornerCenterH && abs(s.y) > cornerCenterV {
                
                // get vector from corner radius center to point on square
                let cornerD = simd_double2(s.x < 0 ? s.x - (-cornerCenterH) : s.x - (cornerCenterH), s.y < 0 ? s.y - (-cornerCenterV) : s.y - (cornerCenterV))
                
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
            let position = CGPoint(x: x + radiusH, y: y + radiusV)
            let angleDegrees = Angle(degrees: angle.degrees + 90.0)
            
            return TickMarkCoordinate(position: position,
                                      angle: angleDegrees)
        }
        
    }
    
    
}



fileprivate struct Preview: View {
    @State var samples: CGFloat = 60
    @State var radius: CGFloat = 20
    @State var width: CGFloat = 2
    @State var height: CGFloat = 40
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangleTickMarkView(tickMarks: Int(samples),
                                         cornerRadius: radius,
                                         tickMarkWidth: width,
                                         tickMarkHeight: height)
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

struct RoundedRectanlgeTickMarkDemo_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
}
