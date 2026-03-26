package com.mangrule.dailathon.domain.managers

import android.telecom.Call
import timber.log.Timber
import com.mangrule.dailathon.presentation.services.DialerInCallService
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages specific call operations (answer, hangup, hold, DTMF, merge, swap).
 * Bridges Flutter requests to the active DialerInCallService.
 */
@Singleton
class CallOperationsManager @Inject constructor() {

  fun answerCall(callId: String? = null) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = if (callId != null) {
          // Find specific call by ID (if tracking by ID)
          service.getCallById(callId)
        } else {
          // Answer the first ringing call
          service.getFirstRingingCall()
        }

        if (call != null) {
          call.answer(Call.STATE_AUDIO_PROCESS)
          Timber.v("Answered call: $callId")
        } else {
          Timber.w("No ringing call found to answer")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error answering call")
      throw e
    }
  }

  fun hangUpCall(callId: String? = null) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = if (callId != null) {
          service.getCallById(callId)
        } else {
          // Hangup active call, or first call if multiple
          service.getFirstActiveCall() ?: service.getFirstCall()
        }

        if (call != null) {
          call.disconnect()
          Timber.v("Disconnected call: $callId")
        } else {
          Timber.w("No active call found to disconnect")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error hanging up call")
      throw e
    }
  }

  fun holdCall(callId: String? = null) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = if (callId != null) {
          service.getCallById(callId)
        } else {
          service.getFirstActiveCall()
        }

        if (call != null && call.state == Call.STATE_ACTIVE) {
          call.hold()
          Timber.v("Placed call on hold: $callId")
        } else {
          Timber.w("No active call found to hold")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error holding call")
      throw e
    }
  }

  fun unholdCall(callId: String? = null) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = if (callId != null) {
          service.getCallById(callId)
        } else {
          service.getFirstHeldCall()
        }

        if (call != null && call.state == Call.STATE_HOLDING) {
          call.unhold()
          Timber.v("Resumed held call: $callId")
        } else {
          Timber.w("No held call found to resume")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error unholding call")
      throw e
    }
  }

  fun sendDtmfTone(digit: String) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = service.getFirstActiveCall()
        if (call != null) {
          call.playDtmfTone(digit[0])
          Timber.v("Sent DTMF tone: $digit")
        } else {
          Timber.w("No active call found to send DTMF")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error sending DTMF tone")
      throw e
    }
  }

  fun mergeActiveCalls() {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        if (service.canMerge()) {
          service.mergeActiveCalls()
          Timber.v("Merged active calls")
        } else {
          Timber.w("Cannot merge: insufficient calls for merge")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error merging calls")
      throw e
    }
  }

  fun swapActiveCalls() {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        if (service.canSwap()) {
          service.swapCalls()
          Timber.v("Swapped active and held calls")
        } else {
          Timber.w("Cannot swap: insufficient calls for swap")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error swapping calls")
      throw e
    }
  }

  fun rejectCall(callId: String? = null) {
    try {
      val service = DialerInCallService.getInstance()
      if (service != null) {
        val call = if (callId != null) {
          service.getCallById(callId)
        } else {
          service.getFirstRingingCall()
        }

        if (call != null && call.state == Call.STATE_RINGING) {
          call.reject(Call.REJECT_REASON_DECLINED)
          Timber.v("Rejected call: $callId")
        } else {
          Timber.w("No ringing call found to reject")
        }
      } else {
        Timber.w("DialerInCallService not active")
      }
    } catch (e: Exception) {
      Timber.e(e, "Error rejecting call")
      throw e
    }
  }
}
