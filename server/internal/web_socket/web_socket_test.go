package web_socket

import (
	"context"
	"testing"
)

func TestParseBinaryMessageRejectsLengthMismatch(t *testing.T) {
	msg := []byte{TextMessage, 0, 0, 0, 10, 'h', 'i'}

	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("parseBinaryMessage panicked on malformed packet: %v", r)
		}
	}()

	msgType, dataLen, payload, ok := parseBinaryMessage(context.Background(), &msg)
	if ok {
		t.Fatalf("expected malformed packet to be rejected, got type=%d len=%d payload=%q", msgType, dataLen, payload)
	}
}

func TestParseBinaryMessageAcceptsValidPacket(t *testing.T) {
	msg := []byte{TextMessage, 0, 0, 0, 2, 'h', 'i'}

	msgType, dataLen, payload, ok := parseBinaryMessage(context.Background(), &msg)
	if !ok {
		t.Fatal("expected valid packet to parse")
	}
	if msgType != TextMessage {
		t.Fatalf("type = %d, want %d", msgType, TextMessage)
	}
	if dataLen != 2 {
		t.Fatalf("dataLen = %d, want 2", dataLen)
	}
	if string(payload) != "hi" {
		t.Fatalf("payload = %q, want hi", payload)
	}
}
