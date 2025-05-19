import Foundation

extension String {
    func formatDateString() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let date = inputFormatter.date(from: self) else {
            // 포맷이 맞지 않는 경우 원본 반환
            return self
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy년 MM월 dd일"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        
        return outputFormatter.string(from: date)
    }
    
    func toShortDate() -> String {
        // 문자열 길이가 충분한지 확인
        guard self.count >= 10 else { return self }
        
        // 날짜 부분만 추출 (yyyy-MM-dd)
        let dateSubstring = String(self.prefix(10))
        
        let components = dateSubstring.split(separator: "-")
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return self
        }
        
        return "\(year)년 \(month)월 \(day)일"
    }
}
