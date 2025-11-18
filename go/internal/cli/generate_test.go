package cli

import (
	"bytes"
	"testing"
)

func TestGenerateCommand(t *testing.T) {
	tests := []struct {
		name    string
		args    []string
		wantErr bool
	}{
		{
			name:    "with prompt argument",
			args:    []string{"Test prompt"},
			wantErr: false,
		},
		{
			name:    "with type flag",
			args:    []string{"--type=task", "Test prompt"},
			wantErr: false,
		},
		{
			name:    "with format flag",
			args:    []string{"--format=json", "Test prompt"},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create command
			cmd := newGenerateCommand()

			// Set args
			cmd.SetArgs(tt.args)

			// Capture output
			buf := new(bytes.Buffer)
			cmd.SetOut(buf)
			cmd.SetErr(buf)

			// Execute
			err := cmd.Execute()

			// Check error expectation
			if (err != nil) != tt.wantErr {
				t.Errorf("command error = %v, wantErr %v", err, tt.wantErr)
			}

			// For now, just verify command runs (stub implementation)
			// TODO: Add real implementation tests when generate is implemented
		})
	}
}

func TestGenerateCommandFlags(t *testing.T) {
	cmd := newGenerateCommand()

	// Test that flags are registered
	flags := []string{
		"type",
		"from",
		"to",
		"template",
		"format",
		"slice",
		"outdir",
		"no-validate",
		"no-cache",
	}

	for _, flagName := range flags {
		if cmd.Flags().Lookup(flagName) == nil {
			t.Errorf("flag %q not registered", flagName)
		}
	}
}
