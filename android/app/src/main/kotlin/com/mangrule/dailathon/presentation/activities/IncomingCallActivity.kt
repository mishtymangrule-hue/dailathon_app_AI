package com.mangrule.dailathon.presentation.activities

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import com.mangrule.dailathon.domain.managers.CallOperationsManager
import com.mangrule.dailathon.presentation.notifications.IncomingCallNotificationManager
import javax.inject.Inject
import kotlinx.coroutines.delay
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf

/**
 * Activity displayed when an incoming call arrives.
 * Shows caller info and answer/decline buttons.
 * Works on lock screen for API 21-34 compatibility.
 */
@AndroidEntryPoint
class IncomingCallActivity : ComponentActivity() {
  @Inject
  lateinit var callOperationsManager: CallOperationsManager

  @Inject
  lateinit var notificationManager: IncomingCallNotificationManager

  private var phoneNumber: String = ""
  private var displayName: String? = null
  private var callId: String? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // Extract call information from intent
    phoneNumber = intent.getStringExtra("phoneNumber") ?: ""
    displayName = intent.getStringExtra("displayName")
    callId = intent.getStringExtra("callId")

    Timber.v("IncomingCallActivity created: phone=$phoneNumber, name=$displayName")

    // Set up window to show on lock screen
    setupWindowFlags()

    // Handle action intents
    when (intent.action) {
      "com.mangrule.dailathon.ANSWER_CALL" -> {
        handleAnswerCall()
        return
      }
      "com.mangrule.dailathon.DECLINE_CALL" -> {
        handleDeclineCall()
        return
      }
    }

    // Show incoming call UI
    setContent {
      MaterialTheme {
        IncomingCallScreen(
          phoneNumber = phoneNumber,
          displayName = displayName,
          onAnswerClick = ::handleAnswerCall,
          onDeclineClick = ::handleDeclineCall,
        )
      }
    }
  }

  private fun setupWindowFlags() {
    // Show above lock screen and keep screen on
    window.addFlags(
      WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
    )

    // For API 27+, use setShowWhenLocked() and setTurnScreenOn()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
      setShowWhenLocked(true)
      setTurnScreenOn(true)
    }
  }

  private fun handleAnswerCall() {
    try {
      Timber.v("Answer button pressed")
      callOperationsManager.answerCall(callId)
      notificationManager.cancelIncomingCallNotification()
      finish()
    } catch (e: Exception) {
      Timber.e(e, "Error answering call")
    }
  }

  private fun handleDeclineCall() {
    try {
      Timber.v("Decline button pressed")
      callOperationsManager.rejectCall(callId)
      notificationManager.cancelIncomingCallNotification()
      finish()
    } catch (e: Exception) {
      Timber.e(e, "Error declining call")
    }
  }

  /**
   * Handle physical buttons during incoming call.
   * Volume up = answer, Volume down = decline
   */
  override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    return when (keyCode) {
      KeyEvent.KEYCODE_VOLUME_UP -> {
        handleAnswerCall()
        true
      }
      KeyEvent.KEYCODE_VOLUME_DOWN -> {
        handleDeclineCall()
        true
      }
      KeyEvent.KEYCODE_HEADSETHOOK -> {
        handleAnswerCall()
        true
      }
      else -> super.onKeyDown(keyCode, event)
    }
  }

  override fun onBackPressed() {
    // Ignore back press to prevent dismissal before user responds
    Timber.v("Back press ignored for incoming call screen")
  }
}

@Composable
private fun IncomingCallScreen(
  phoneNumber: String,
  displayName: String?,
  onAnswerClick: () -> Unit,
  onDeclineClick: () -> Unit,
) {
  val elapsedSeconds = remember { mutableStateOf(0L) }
  val pulseAlpha = remember { mutableStateOf(1f) }

  // Update ringing timer
  LaunchedEffect(Unit) {
    var seconds = 0L
    while (true) {
      delay(1000)
      seconds++
      elapsedSeconds.value = seconds
    }
  }

  // Pulsing animation for ring indicator
  LaunchedEffect(Unit) {
    while (true) {
      delay(600)
      pulseAlpha.value = 0.3f
      delay(600)
      pulseAlpha.value = 1f
    }
  }

  Surface(
    modifier = Modifier.fillMaxSize(),
    color = Color.Black,
  ) {
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(32.dp),
      verticalArrangement = Arrangement.SpaceEvenly,
      horizontalAlignment = Alignment.CenterHorizontally,
    ) {
      Spacer(modifier = Modifier.height(32.dp))

      // Pulsing ring indicator at top
      Box(
        modifier = Modifier
          .size(12.dp)
          .background(Color.Green, CircleShape)
          .alpha(pulseAlpha.value)
      )

      // Caller avatar or initials
      Box(
        modifier = Modifier
          .size(120.dp)
          .background(Color(0xFF1E3A8A), CircleShape),
        contentAlignment = Alignment.Center,
      ) {
        Text(
          text = (displayName?.take(2) ?: "?").uppercase(),
          fontSize = 48.sp,
          color = Color.White,
          fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
        )
      }

      // Caller name (large, centered)
      Text(
        text = displayName ?: "Unknown Caller",
        fontSize = 32.sp,
        color = Color.White,
        modifier = Modifier.padding(bottom = 8.dp),
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
      )

      // Phone number
      Text(
        text = phoneNumber,
        fontSize = 18.sp,
        color = Color(0xFF9CA3AF),
        modifier = Modifier.padding(bottom = 32.dp),
      )

      // Ringing status with elapsed time
      Row(
        modifier = Modifier
          .fillMaxWidth()
          .padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
      ) {
        Box(
          modifier = Modifier
            .size(8.dp)
            .background(Color.Green, CircleShape)
            .alpha(pulseAlpha.value)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
          text = "Ringing... ${elapsedSeconds.value}s",
          fontSize = 14.sp,
          color = Color.White,
        )
      }

      Spacer(modifier = Modifier.height(32.dp))

      // Answer and Decline buttons
      Row(
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 24.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
      ) {
        // Decline button (left, red)
        Button(
          onClick = onDeclineClick,
          modifier = Modifier
            .size(72.dp),
          shape = CircleShape,
          colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFDC2626)),
        ) {
          Icon(
            imageVector = Icons.Filled.CallEnd,
            contentDescription = "Decline",
            tint = Color.White,
            modifier = Modifier.size(36.dp),
          )
        }

        Spacer(modifier = Modifier.width(32.dp))

        // Answer button (right, green, slightly larger)
        Button(
          onClick = onAnswerClick,
          modifier = Modifier
            .size(80.dp),
          shape = CircleShape,
          colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10B981)),
        ) {
          Icon(
            imageVector = Icons.Filled.Call,
            contentDescription = "Answer",
            tint = Color.White,
            modifier = Modifier.size(40.dp),
          )
        }
      }

      Spacer(modifier = Modifier.height(48.dp))

      // Controls hint
      Text(
        text = "↑ Volume Up = Answer  ↓ Volume Down = Decline",
        fontSize = 12.sp,
        color = Color(0xFF6B7280),
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
      )

      Spacer(modifier = Modifier.height(24.dp))
    }
  }
}
