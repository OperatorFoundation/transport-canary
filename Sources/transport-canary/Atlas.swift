struct Country
{
    let code: String
    let name: String
    
    init(code: String, name: String)
    {
        self.code = code.uppercased()
        self.name = name.capitalized
    }
    
    var emojiFlag: String
    {
        return code.unicodeScalars.map { String(regionalIndicatorSymbol(unicodeScalar: $0)!) } .joined()
    }
    
    func regionalIndicatorSymbol(unicodeScalar: UnicodeScalar) -> UnicodeScalar?
    {
        let uppercaseA = UnicodeScalar("A")!
        let regoinalIndicatorSymbolA = UnicodeScalar("\u{1f1e6}")!
        let distance = unicodeScalar.value - uppercaseA.value
        
        return UnicodeScalar(regoinalIndicatorSymbolA.value + distance)
    }
    
}
