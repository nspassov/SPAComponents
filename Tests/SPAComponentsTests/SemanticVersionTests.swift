@testable import SPAComponents
import Testing

struct SemanticVersionTests {
    
    @Test
    func whenIncorrectInputIsProvided_thenSemanticVersionIsNil() {
        
        #expect(SemanticVersion("a") == nil)
        #expect(SemanticVersion("1.2") == nil)
        #expect(SemanticVersion("1.2.3.4") == nil)
        #expect(SemanticVersion("1.2.3a") == nil)
    }
    
    @Test
    func whenSemanticVersionsAreCreated_thenComparisonWorksCorrectly() {
        let s1 = SemanticVersion("1.2.3")!
        let s2 = SemanticVersion("1.2.0")!
        let s3 = SemanticVersion("1.0.3")!
        let s4 = SemanticVersion("2.0.0")!
        
        #expect(s1 > s2)
        #expect(s1 > s3)
        #expect(s1 < s4)
        #expect(s2 > s3)
        #expect(s2 < s4)
        #expect(s3 < s4)
    }
}
