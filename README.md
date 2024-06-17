# Seer - Swift Native applications for Nostr's Nip29

### Here be dragons 🚨🚨🚨
This repo is a work in progress. Its not ready for outside consumption at the moment, but will be soon. Im providing the code here simply for review and transparency. When its ready I will provide binaries for testing.

## Overview
Seer is a powerful, open-source application designed for seamless group communication within the Nostr protocol utlizing [Nip29](https://github.com/nostr-protocol/nips/blob/master/29.md). Built using Swift, it is optimized for all Apple platforms including macOS, iOS, iPadOS, and potentially visionOS.

## Key Features
- **Group Communication:** Create and manage relay-based groups similar to Slack or Telegram.
- **Platform Optimization:** Native performance and UI consistency across macOS, iOS, and iPadOS.
- **Swift and SwiftUI:** Utilizes Swift for maximum performance and code maintainability. SwiftUI ensures reusable code and a unified user experience.
- **Self-Publishing:** Initial release on macOS will be self-published, bypassing potential App Store approval issues. *Of course iOS and iPadOS version will need to go through the App Store approval. It's doable, but with macOS we can speed up release progress by self publishing.*
- **Relay Managment:** Allow admin's to manage their relays and groups directly from the app. It should be easy for admins to do these things without having to login to relay servers and manage config files.
- **Secure Key Store:** The app will allow the user to create and manage multiple key's securly by storing them in the keychain.
- **On Device Language Conversion:** Utilzing apples on-device language api, the app can make it easy to convert conversations to the users native language.
- **Key Metadata Management**: Profile management made easy
- **Kind 10002 List Support:** The app respects relay lists as it should.

## Overall Motivation
We rely on group communication tools that are not open and have many of the same issues as current social protocols. With Nip29, the idea is to allow people stand up their own Nostr relay's and manage their own group communication. We are striving for making nip29 relay deployment as simple as deploying a server and running a single command. Allowing the user to select configurations at deploy stage. This is crucial. We need more people running relays and less "Mega relays". This is how we decentralize. If you get banned from a group and you want your voice to be heard, standup your own relay. It should be simple.

## Plans
- macOS First: Initial focus on macOS to deliver a robust application for desktop users.
- iOS and iPadOS: Subsequent releases will target iOS and iPadOS, utilizing the shared SwiftUI codebase for a streamlined development process.
- Windows/Linux/Android (Using platform native tools) Long term goal


## Conclusion
Seer aims to enhance group communication within the Nostr ecosystem by providing a high-performance, maintainable, and user-friendly application.
