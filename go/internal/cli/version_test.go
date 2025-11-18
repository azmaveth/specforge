package cli

import (
	"bytes"
	"testing"

	"github.com/spf13/cobra"
)

func TestVersionCommand(t *testing.T) {
	tests := []struct {
		name    string
		version string
		commit  string
		date    string
		verbose bool
		want    string
	}{
		{
			name:    "basic version",
			version: "1.0.0",
			commit:  "abc123",
			date:    "2025-01-18",
			verbose: false,
			want:    "spec version 1.0.0\n",
		},
		{
			name:    "verbose version",
			version: "1.0.0",
			commit:  "abc123",
			date:    "2025-01-18",
			verbose: true,
			want:    "spec version 1.0.0\ncommit: abc123\nbuilt: 2025-01-18\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Set verbose flag
			verbose = tt.verbose

			// Create command
			cmd := newVersionCommand(tt.version, tt.commit, tt.date)

			// Capture output
			buf := new(bytes.Buffer)
			cmd.SetOut(buf)
			cmd.SetErr(buf)

			// Execute
			if err := cmd.Execute(); err != nil {
				t.Fatalf("command failed: %v", err)
			}

			// Check output
			got := buf.String()
			if got != tt.want {
				t.Errorf("version output mismatch\ngot:  %q\nwant: %q", got, tt.want)
			}
		})
	}
}

func TestVersionCommandIntegration(t *testing.T) {
	// Reset verbose flag to ensure test isolation
	oldVerbose := verbose
	verbose = false
	defer func() { verbose = oldVerbose }()

	// Create root command with version subcommand
	rootCmd := &cobra.Command{Use: "spec"}
	rootCmd.AddCommand(newVersionCommand("test", "commit", "date"))

	// Execute version command
	rootCmd.SetArgs([]string{"version"})

	buf := new(bytes.Buffer)
	rootCmd.SetOut(buf)
	rootCmd.SetErr(buf)

	if err := rootCmd.Execute(); err != nil {
		t.Fatalf("command execution failed: %v", err)
	}

	// Verify output contains version
	output := buf.String()
	if output != "spec version test\n" {
		t.Errorf("unexpected output: %q", output)
	}
}
