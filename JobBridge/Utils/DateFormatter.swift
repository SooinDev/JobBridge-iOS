import Foundation

extension String {
    func formatDateString() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let date = inputFormatter.date(from: self) else {
            return self
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy년 MM월 dd일"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        
        return outputFormatter.string(from: date)
    }
    
    func toFormattedDate() -> String {
        return formatDateString()
    }
    
    func toShortDate() -> String {
        guard self.count >= 10 else { return self }
        
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
    
    // 🔥 매칭 기능에서 사용할 상대적 시간 표시
    func toRelativeTime() -> String {
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: self) {
                let now = Date()
                let timeInterval = now.timeIntervalSince(date)
                
                if timeInterval < 60 {
                    return "방금 전"
                } else if timeInterval < 3600 {
                    return "\(Int(timeInterval / 60))분 전"
                } else if timeInterval < 86400 {
                    return "\(Int(timeInterval / 3600))시간 전"
                } else if timeInterval < 2592000 { // 30일
                    return "\(Int(timeInterval / 86400))일 전"
                } else {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "yyyy년 M월 d일"
                    outputFormatter.locale = Locale(identifier: "ko_KR")
                    return outputFormatter.string(from: date)
                }
            }
        }
        
        return self
    }
    
    // 🔥 상세한 날짜 포맷 (매칭 결과용)
    func toDetailedDate() -> String {
        let inputFormatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in inputFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            
            if let date = formatter.date(from: self) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy년 M월 d일 HH:mm"
                outputFormatter.locale = Locale(identifier: "ko_KR")
                return outputFormatter.string(from: date)
            }
        }
        
        return self
    }
    
    // 🔥 마감일 포맷 (D-day 스타일)
    func toDeadlineFormat() -> String {
        let inputFormatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in inputFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            
            if let date = formatter.date(from: self) {
                let now = Date()
                let calendar = Calendar.current
                let daysLeft = calendar.dateComponents([.day], from: now, to: date).day ?? 0
                
                if daysLeft < 0 {
                    return "마감"
                } else if daysLeft == 0 {
                    return "오늘 마감"
                } else if daysLeft <= 7 {
                    return "D-\(daysLeft)"
                } else {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "M월 d일까지"
                    outputFormatter.locale = Locale(identifier: "ko_KR")
                    return outputFormatter.string(from: date)
                }
            }
        }
        
        return self
    }
}
