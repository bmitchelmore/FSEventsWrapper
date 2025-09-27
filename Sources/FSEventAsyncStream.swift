import Foundation



/* Needed to guard the availability of `AsyncStream.makeStream`.
 * Once Xcode 15 is released, it should be safe to remove this. */
#if compiler(>=5.9)

/** An AsyncSequence of `FSEvent` objects. */
@available(macOS 10.15, *)
public struct FSEventAsyncStream : AsyncSequence {
	
	public typealias Element = FSEvent
	
	public struct FSEventAsyncIterator : AsyncIteratorProtocol {
		
		private let eventStream: FSEventStream?
		private var streamIterator: AsyncStream<FSEvent>.Iterator
		
		init(paths: [String], flags: FSEventStreamCreateFlags) {
			let (stream, continuation) = AsyncStream<FSEvent>.makeStream()
			
			self.eventStream = FSEventStream(paths: paths, fsEventStreamFlags: flags, callback: { _, event in
				continuation.yield(event)
			})
			
			self.streamIterator = stream.makeAsyncIterator()
			self.eventStream?.startWatching()
			
			if eventStream == nil {
				continuation.finish()
			}
		}
		
		public mutating func next() async -> FSEvent? {
			await streamIterator.next()
		}
		
	}
	
	public let paths: [String]
	public let flags: FSEventStreamCreateFlags
	
	public init(paths: [String], flags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)) {
		self.paths = paths
		self.flags = flags
	}
	
	public init(path: String, flags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)) {
		self.paths = [path]
		self.flags = flags
	}
	
	public func makeAsyncIterator() -> FSEventAsyncIterator {
		FSEventAsyncIterator(paths: paths, flags: flags)
	}
	
}

#endif
