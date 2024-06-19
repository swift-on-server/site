import struct Foundation.UUID

actor BankAccount {
    private var funds: Double = 35

    func checkBalance() -> Double {
        return funds
    }
}

struct BookOrder: Identifiable {
    let id = UUID()
    let book: Book

    func delivery() async throws -> Book {
        // Delivery takes time!!
        try await Task.sleep(for: .seconds(1))
        return book
    }
}

struct Book {
    let price: Double

    init(price: Double) {
        self.price = price
    }

    func buy() async throws -> BookOrder {
        BookOrder(book: self)
    }
}

actor BookStore {
    // snippet.asyncSequence
    struct Books: AsyncSequence {
        typealias Element = Book
        let database: [Book]

        struct AsyncIterator: AsyncIteratorProtocol {
            typealias Element = Book
            var database: [Book]
            var readerIndex = 0

            mutating func next() async -> Book? {
                if readerIndex == database.count {
                    return nil
                }

                let book = database[readerIndex]
                readerIndex += 1
                return book
            }
        }

        func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(database: database)
        }
    }
    // snippet.end

    private static let onlyBookStoreInTown = BookStore()
    private var books = [Book]()

    init() {
        self.books = [
            Book(price: 10),
            Book(price: 15),
            Book(price: 9.95),
            Book(price: 10),
            Book(price: 25),
            Book(price: 8),
            Book(price: 15),
        ]
    }

    // snippet.browseBooks
    func browseBooks() -> Books {
        Books(database: books)
    }
    // snippet.end

    static func discover() async -> BookStore {
        // Return the book store instance
        return Self.onlyBookStoreInTown
    }
}

// snippet.buyBooks
func buyBooks(from bankAccount: BankAccount) async throws -> [Book] {
    // Resolve this concurrently
    async let balance = await bankAccount.checkBalance()

    let store = await BookStore.discover()
    var budget = await balance
    var boughtBooks: [Book] = []
    let books = await store.browseBooks()
    for await book in books where book.price <= budget {
        let order = try await book.buy()
        let book = try await order.delivery()
        budget -= book.price
        boughtBooks.append(book)
    }
    return boughtBooks
}
// snippet.end

// snippet.buyBooksInBackground
func buyBooksInBackground() async {
    let store = await BookStore.discover()
    for await book in await store.browseBooks() {
        Task {
            let order = try await book.buy()
            _ = try await order.delivery()
        }
    }
}
// snippet.end
