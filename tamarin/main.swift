//
//  main.swift
//  tamarin
//
//  Created by RealKGB on 7/8/23.
//

import Foundation

var interface = "/dev/tty.usbmodem313371"
var monitor = "/dev/tty.usbmodem313374"

print("\u{001B}[?1049h\u{001B}[s")
setTerminalTitle("tamarin")

let fileManager = FileManager.default
let storagePath = fileManager.homeDirectoryForCurrentUser.path + "/.tamarin"

if fileManager.fileExists(atPath: storagePath) {
    do {
        let storageContents = try String(contentsOf: URL(fileURLWithPath: storagePath), encoding: .utf8)
        let storageArray = storageContents.components(separatedBy: .newlines)
        if storageArray.count == 2 {
            interface = storageArray[0]
            monitor = storageArray[1]
        }
    } catch {
        print(".tamarin file is either corrupted or of invalid type. Using default values")
    }
}

while true {

    print("Welcome to the Tamarin cable!")
    print("1: Tamarin cable interface\n2: Tamarin UART monitor\n3: Set Tamarin usbmodem locations")
    fwrite("> ", 1, 2, stdout)
    fflush(stdout)

    if let input = readLine() {
        switch input {
        case "1":
            setTerminalTitle("tamarin - interface")
            if let interfacePid = getProcessID(interface) {
                spawn("/usr/bin/env", ["kill", String(interfacePid)])
            }
            spawn("/usr/bin/screen", [interface])
            break
        case "2":
            setTerminalTitle("tamarin - monitor")
            if let monitorPid = getProcessID(monitor) {
                spawn("/usr/bin/env", ["kill", String(monitorPid)])
            }
            spawn("/usr/bin/screen", [monitor])
            break
        case "3":
            print(fileManager.homeDirectoryForCurrentUser.path + "/.tamarin")
            let storagePath = fileManager.homeDirectoryForCurrentUser.path + "/.tamarin"
            var text = ""
            print("\u{001B}[?1049h\u{001B}[s")
            while true {
                print("Input the usbmodem for the Tamarin cable interface\n> ", terminator: "")
                if let input = readLine() {
                    text += input
                    text += "\n"
                    break
                }
            }
            while true {
                print("Input the usbmodem for the Tamarin cable monitor\n> ", terminator: "")
                if let input = readLine() {
                    text += input
                    break
                }
            }
            try! text.write(toFile: storagePath, atomically: true, encoding: .utf8)
            break
        default:
            print("", terminator: "")
        }
    } else { }
}

func setTerminalTitle(_ title: String) {
    print("\u{001B}]0;\(title)\u{0007}", terminator: "")
    fflush(stdout)
}

func spawn(_ path: String, _ arguments: [String]) {
    let task = Process()
    task.launchPath = path
    
    task.arguments = arguments
    task.standardInput = FileHandle.standardInput
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    task.launch()
    
    task.waitUntilExit()
}

func getProcessID(_ devicePath: String) -> Int32? {
    let task = Process()
    task.launchPath = "/usr/sbin/lsof"
    task.arguments = ["-t", devicePath]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines),
       let pid = Int32(output) {
        return pid
    }
    
    return nil
}

func writeZero() {
    let zeroWidthSpace = "\u{200B}"
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["echo", "-n", zeroWidthSpace]
    process.standardOutput = FileHandle.standardOutput
    process.launch()
    process.waitUntilExit()
}
