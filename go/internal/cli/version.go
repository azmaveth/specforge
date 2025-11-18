package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newVersionCommand(version, commit, date string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Fprintf(cmd.OutOrStdout(), "spec version %s\n", version)
			if verbose {
				fmt.Fprintf(cmd.OutOrStdout(), "commit: %s\n", commit)
				fmt.Fprintf(cmd.OutOrStdout(), "built: %s\n", date)
			}
		},
	}
}
