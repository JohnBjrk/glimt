/// system is unusable
pub external type Emergency

/// action must be taken immediately
pub external type Alert

/// critical conditions
pub external type Critical

/// error conditions
pub external type Error

/// warning conditions
pub external type Warning

/// normal but significant conditions
pub external type Notice

/// informational messages
pub external type Info

/// debug-level messages
pub external type Debug

/// all levels
pub external type All

/// No level
pub external type None

/// Logger levels valid list
pub type Level {
  Emergency
  Alert
  Critical
  Error
  Warning
  Notice
  Info
  Debug
}
