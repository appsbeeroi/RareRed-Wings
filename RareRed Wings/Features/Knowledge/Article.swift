import Foundation

struct KnowledgeArticle: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let content: String
    let category: ArticleCategory
    let hasExternalLink: Bool
    let externalURL: String?
    
    init(id: UUID = UUID(), title: String, subtitle: String, content: String, category: ArticleCategory, hasExternalLink: Bool = false, externalURL: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.category = category
        self.hasExternalLink = hasExternalLink
        self.externalURL = externalURL
    }
}

enum ArticleCategory: String, CaseIterable, Codable {
    case redBook = "red_book"
    case behavior = "behavior"
    case resources = "resources"
    
    var displayName: String {
        switch self {
        case .redBook:
            return "Red book & bird protection"
        case .behavior:
            return "Behavior & Habitats"
        case .resources:
            return "Resources & Organizations"
        }
    }
}

extension KnowledgeArticle {
    static let seed: [KnowledgeArticle] = [
        KnowledgeArticle(
            title: "Threats to White-Tailed Eagles",
            subtitle: "White-tailed eagles are under threat due to the loss of nesting sites",
            content: "White-tailed eagles face significant challenges in their natural habitats. The primary threat comes from habitat destruction, particularly the loss of old-growth forests where they build their massive nests. These birds require large territories and specific nesting conditions that are becoming increasingly rare due to human development and logging activities.",
            category: .redBook,
            hasExternalLink: true,
            externalURL: "https://en.wikipedia.org/wiki/White-tailed_eagle"
        ),
        KnowledgeArticle(
            title: "Conservation Success Stories",
            subtitle: "How protected areas have helped bird populations recover",
            content: "Protected areas have proven to be crucial for bird conservation. Many species that were once on the brink of extinction have made remarkable recoveries thanks to dedicated conservation efforts. These success stories demonstrate the importance of habitat protection and the positive impact of conservation programs worldwide.",
            category: .redBook,
            hasExternalLink: false,
            externalURL: ""
        ),
        KnowledgeArticle(
            title: "Illegal Wildlife Trade Impact",
            subtitle: "The devastating effects of illegal bird trading on populations",
            content: "Illegal wildlife trade poses one of the greatest threats to bird populations globally. Many species are captured and sold illegally, often for the pet trade or traditional medicine. This practice not only reduces wild populations but also disrupts natural ecosystems and breeding patterns.",
            category: .redBook,
            hasExternalLink: true,
            externalURL: "https://www.worldwildlife.org/threats/illegal-wildlife-trade"
        ),
        
        KnowledgeArticle(
            title: "Migration Patterns of Arctic Birds",
            subtitle: "Understanding the incredible journeys of migratory species",
            content: "Arctic birds undertake some of the most remarkable migrations on Earth, traveling thousands of miles between breeding and wintering grounds. These journeys are driven by seasonal changes in food availability and weather conditions. The precision of their navigation abilities continues to amaze scientists studying these incredible travelers.",
            category: .behavior,
            hasExternalLink: true,
            externalURL: "https://en.wikipedia.org/wiki/Bird_migration"
        ),
        KnowledgeArticle(
            title: "Nesting Behaviors in Forest Birds",
            subtitle: "How different species adapt their nesting strategies",
            content: "Forest birds have developed diverse nesting strategies to maximize their reproductive success. Some species build elaborate nests high in the canopy, while others prefer ground-level sites. These adaptations reflect the specific challenges and opportunities presented by their forest habitats, including predator avoidance and resource availability.",
            category: .behavior,
            hasExternalLink: true,
            externalURL: "https://en.wikipedia.org/wiki/Bird_nest"
        ),
        KnowledgeArticle(
            title: "Feeding Strategies of Raptors",
            subtitle: "The hunting techniques and dietary preferences of birds of prey",
            content: "Raptors have evolved sophisticated hunting techniques that vary greatly between species. From the high-speed dives of peregrine falcons to the patient stalking of owls, each species has developed specialized strategies for capturing prey. Their dietary preferences often reflect the specific ecosystems they inhabit and the availability of different prey species.",
            category: .behavior,
            hasExternalLink: true,
            externalURL: "https://en.wikipedia.org/wiki/Bird_of_prey"
        ),
        
        KnowledgeArticle(
            title: "International Bird Conservation Networks",
            subtitle: "Global organizations working to protect bird species worldwide",
            content: "International conservation networks play a vital role in coordinating bird protection efforts across borders. These organizations facilitate information sharing, coordinate conservation strategies, and provide funding for critical research and protection programs. Their work is essential for addressing threats that affect birds across multiple countries and continents.",
            category: .resources,
            hasExternalLink: true,
            externalURL: "https://www.birdlife.org/"
        ),
        KnowledgeArticle(
            title: "Citizen Science in Bird Monitoring",
            subtitle: "How birdwatchers contribute to scientific research and conservation",
            content: "Citizen science has revolutionized bird monitoring and conservation efforts. Birdwatchers around the world contribute valuable data through organized counts, migration tracking, and habitat monitoring programs. This grassroots approach has provided scientists with unprecedented amounts of data and has helped identify population trends and conservation priorities.",
            category: .resources,
            hasExternalLink: true,
            externalURL: "https://ebird.org/"
        ),
        KnowledgeArticle(
            title: "Technology in Bird Conservation",
            subtitle: "Modern tools and techniques used in bird research and protection",
            content: "Modern technology has transformed bird conservation efforts, providing researchers with powerful new tools for monitoring and protecting species. GPS tracking devices, satellite imagery, and acoustic monitoring systems have revolutionized our understanding of bird behavior and migration patterns. These technologies are helping conservationists develop more effective protection strategies.",
            category: .resources,
            hasExternalLink: true,
            externalURL: "https://www.birds.cornell.edu/home/"
        ),
        KnowledgeArticle(
            title: "Educational Programs for Bird Conservation",
            subtitle: "How education and awareness campaigns help protect bird species",
            content: "Education plays a crucial role in bird conservation by raising awareness about the importance of protecting these species and their habitats. Educational programs target various audiences, from school children to local communities, teaching them about bird ecology, conservation challenges, and practical ways to contribute to protection efforts.",
            category: .resources,
            hasExternalLink: true,
            externalURL: "https://www.audubon.org/conservation/education"
        )
    ]
}
