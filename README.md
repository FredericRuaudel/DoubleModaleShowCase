# DoubleModaleShowCase
Showcase the double modal presentation issue in SwiftUI and UIKit with TCA

At the time of writing, the issue is still present in TCA 1.15.2.

This issue is discussed in the following thread: https://github.com/pointfreeco/swift-composable-architecture/discussions/3371#discussioncomment-10619643

## Description

This project is a showcase of a bug that occurs when you present a modale and then present a popover over a popover from that modale, the behavior of SwiftUI and UIKit are not consistent.
Two usecases are tested in this project for both UIKit and SwiftUI navigation:
    1. Setting the second popover directly over the first one
    2. Dismissing the first one, waiting 300ms then presenting the second one.
    
In usecase 1, the UIKit navigation will not present the second popover, while the SwiftUI navigation will present it correctly.
In usecase 2, the UIKit navigation will dismiss the second popover before it is displayed and also dismiss the modale view controller, while the SwiftUI navigation will dismiss the second popover before it is shown but keep the modale.

## Project demo

https://github.com/user-attachments/assets/a15dfbf6-3a5c-494f-9627-e95b00d99777

## Issue

See below the sequence diagrams that illustrate the issue for both SwiftUI and UIKit navigation.

### SwiftUI

```mermaid
sequenceDiagram
    autonumber
    box <BR/>SWIFTUI<BR/>
    actor User
    participant CR as ContentReducer
    participant CV as ContentView
    participant MR as ModaleReducer
    participant MV as ModaleView
    participant SOR as ShareOptionReducer
    participant SOV as ShareOptionView
    participant SR as ShareSheetReducer
    participant SV as ShareSheetView
    end
    
    User -->> CV: tap show modal button
    CV -->> CR: send(.showModaleButtonTapped)
    CR -->> MV: presents as modale
    User -->> MV: tap share button
    MV -->> MR: send(.shareButtonTapped)
    MR -->> SOV: presents as popover
    alt direct share
        User -->> SOV: tap share button
        SOV -->> SOR: send(.shareButtonTapped)
        SOR -->> MR: send(.delegate(.share(XX)))
        MR -->> SV: present as popover
        SV -->> SR: send(.closeButtonTapped)
        SR -->> MR: send(.delegate(.closeSharing))
        note over MR,SOV: GOOD: everything OK
    else dismiss then share
        User -->> SOV: tap share & dismiss button
        SOV -->> SOR: send(.dismissThenShareButtonTapped)
        SOR -->> MR: send(.delegate(.dismissThenShare(XX)))
        MR -->> SOR: dismiss
        MR -->> MR: wait 300ms
        MR -->> MR: send(.showShareSheet)
        MR -->> SV: present as popover
        MR -->> MR: send(.dismiss)
        note over MR,SOV: BAD: Auto dismiss that prevent second popover to appear
    else cancel
        User -->> SOV: tap cancel button
        SOV -->> SOR: send(.cancelButtonTapped)
        SOR -->> MR: send(.delegate(.cancelSharing)
        MR -->> SOR: dismiss
        note over MR,SOV: GOOD: everything OK
    end
```

### UIKit

```mermaid
sequenceDiagram
    autonumber
    box <br/>UIKIT<br/>
    actor User
    participant CR as ContentReducer
    participant CV as ContentViewController
    participant MR as ModaleReducer
    participant MV as ModaleViewController
    participant SOR as ShareOptionReducer
    participant SOV as ShareOptionViewController
    participant SR as ShareSheetReducer
    participant SV as ShareSheetViewController
    end
    
    User -->> CV: tap show modal button
    CV -->> CR: send(.showModaleButtonTapped)
    CR -->> MV: presents as modale
    User -->> MV: tap share button
    MV -->> MR: send(.shareButtonTapped)
    MR -->> SOV: presents as popover
    alt direct share
        User -->> SOV: tap share button
        SOV -->> SOR: send(.shareButtonTapped)
        SOR -->> MR: send(.delegate(.share(XX)))
        MR -->> SV: try to present as popover
        note over MR,SOV: BAD: 1st popover remains visible and<br/>next one doesn't show up
    else dismiss then share
        User -->> SOV: tap share & dismiss button
        SOV -->> SOR: send(.dismissThenShareButtonTapped)
        SOR -->> MR: send(.delegate(.dismissThenShare(XX)))
        MR -->> SOR: dismiss
        MR -->> MR: wait 300ms
        MR -->> MR: send(.showShareSheet)
        MR -->> SV: try present as popover
        MR -->> MR: send(.dismiss)
        note over MR,SOV: BAD: Auto dismiss that prevent second popover to<br/>appear and also dismiss the ModaleViewController
    else cancel
        User -->> SOV: tap cancel button
        SOV -->> SOR: send(.cancelButtonTapped)
        SOR -->> MR: send(.delegate(.cancelSharing)
        MR -->> SOR: dismiss
        note over MR,SOV: GOOD: everything OK
    end
```

## Workaround

I finally found a workaround to this issue. In fact, the waiting time between the dismiss of the first popover and the presentation of the second one is the key to the issue. If you wait a little bit more before presenting the second popover, the UIKit navigation will work as expected. 

**Waiting 300ms was too little so I tried increasing the value and found that 1sec was working fine**. 

The current version of the repo is reflecting this change.


