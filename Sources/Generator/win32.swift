// import WinSDK
// import SystemPackage
// import Foundation

// struct PathError: Error {}

// func programFilesX86Path() throws -> FilePath {
// 	var pwstrPath: PWSTR? = nil
// 	defer {
// 		CoTaskMemFree(pwstrPath)
// 	}
	
// 	try withUnsafePointer(to: FOLDERID_ProgramFilesX86) { idPointer in
// 		let hr = SHGetKnownFolderPath(idPointer, 0, nil, &pwstrPath)

// 		guard hr == S_OK else {
// 			throw PathError()
// 		}
// 	}
// 	return FilePath(platformString: pwstrPath!)
// }

// // todo: remove recursion
// class DirectoryItems: Sequence, IteratorProtocol {
// 	private var handle: HANDLE
// 	private var findData: WIN32_FIND_DATAW
// 	private var first = true

// 	init(in path: FilePath) {
// 		var localFindData = WIN32_FIND_DATAW()
// 		handle = path.appending("*").withPlatformString { pointer in
// 			FindFirstFileW(pointer, &localFindData)
// 		}
// 		findData = localFindData
// 	}

// 	private func close() {
// 		FindClose(handle)
// 	}

// 	deinit {
// 		if handle != INVALID_HANDLE_VALUE {
// 			close()
// 		}
// 	}

// 	func next() -> String? {
// 		if handle == INVALID_HANDLE_VALUE {
// 			return nil
// 		}

// 		if first {
// 			first = false
// 		} else if !FindNextFileW(handle, &findData) {
// 			close()
// 			handle = INVALID_HANDLE_VALUE
// 			return nil
// 		}


// 		let item = withUnsafePointer(to: &findData.cFileName.0) { pointer in
// 			String(platformString: pointer)
// 		}

// 		if item == "." || item == ".." {
// 			return next()
// 		}
// 		return item
// 	}
// }

// struct Win32Error: Error {
// 	let errorCode: DWORD = GetLastError()
// }

// struct File: ~Copyable {
// 	var handle: HANDLE

// 	init(at path: FilePath) throws {
// 		handle = path.withPlatformString { pointer in
// 			CreateFileW(
// 				pointer,
// 				GENERIC_READ,
// 				DWORD(FILE_SHARE_READ),
// 				nil,
// 				DWORD(OPEN_EXISTING),
// 				DWORD(FILE_ATTRIBUTE_NORMAL),
// 				nil
// 			)
// 		}

// 		if handle == INVALID_HANDLE_VALUE {
// 			throw Win32Error()
// 		}
// 	}

// 	deinit {
// 		CloseHandle(handle)
// 	}

// 	func readAll() throws -> Data {
// 		var size = LARGE_INTEGER()
// 		guard GetFileSizeEx(handle, &size) else {
// 			throw Win32Error()
// 		}
// 		let totalFileSize = size.QuadPart
// 		var data = Data(count: Int(totalFileSize))

// 		var totalBytesRead: Int64 = 0

// 		while totalBytesRead < size.QuadPart {
// 			try data.withUnsafeMutableBytes { buffer in
// 				guard let baseAddress = buffer.baseAddress else {
// 					return
// 				}

// 				let remaining = totalFileSize - totalBytesRead
// 				let bytesToRead = UInt32(min(remaining, Int64(UInt32.max)))
// 				let currentPointer = baseAddress.advanced(by: Int(totalBytesRead))

// 				var bytesRead: UInt32 = 0
// 				guard ReadFile(
// 					handle,
// 					currentPointer,
// 					bytesToRead,
// 					&bytesRead,
// 					nil
// 				) else {
// 					throw Win32Error()
// 				}

// 				totalBytesRead += Int64(bytesRead)
// 			}
// 		}
// 		return data
// 	}
// }
