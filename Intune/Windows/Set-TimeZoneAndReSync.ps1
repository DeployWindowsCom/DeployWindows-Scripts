
# Sätter timezon to Europe Standard
# Startar w32time tjänten som hanterar synkronizeringen av tiden

Set-TimeZone -Id "W. Europe Standard Time"

Start-Service w32time
#Force resync
w32tm /resync /force