package config

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestLoad_Defaults(t *testing.T) {
	// Load with no config file
	cfg, err := Load("")
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	// Check defaults
	if cfg.DefaultModel != "openai" {
		t.Errorf("DefaultModel = %q, want %q", cfg.DefaultModel, "openai")
	}

	if cfg.Cache.Backend != "mem" {
		t.Errorf("Cache.Backend = %q, want %q", cfg.Cache.Backend, "mem")
	}

	if cfg.Cache.TTL != time.Hour {
		t.Errorf("Cache.TTL = %v, want %v", cfg.Cache.TTL, time.Hour)
	}

	if cfg.Output.Dir != "./specs" {
		t.Errorf("Output.Dir = %q, want %q", cfg.Output.Dir, "./specs")
	}

	if cfg.Log.Level != "info" {
		t.Errorf("Log.Level = %q, want %q", cfg.Log.Level, "info")
	}
}

func TestLoad_FromEnv(t *testing.T) {
	// Set environment variables
	os.Setenv("SPECFORGE_DEFAULT_MODEL", "anthropic:claude-3-opus")
	os.Setenv("SPECFORGE_CACHE_BACKEND", "disk")
	os.Setenv("SPECFORGE_OUTPUT_DIR", "/tmp/specs")
	defer func() {
		os.Unsetenv("SPECFORGE_DEFAULT_MODEL")
		os.Unsetenv("SPECFORGE_CACHE_BACKEND")
		os.Unsetenv("SPECFORGE_OUTPUT_DIR")
	}()

	cfg, err := Load("")
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.DefaultModel != "anthropic:claude-3-opus" {
		t.Errorf("DefaultModel = %q, want %q", cfg.DefaultModel, "anthropic:claude-3-opus")
	}

	if cfg.Cache.Backend != "disk" {
		t.Errorf("Cache.Backend = %q, want %q", cfg.Cache.Backend, "disk")
	}

	if cfg.Output.Dir != "/tmp/specs" {
		t.Errorf("Output.Dir = %q, want %q", cfg.Output.Dir, "/tmp/specs")
	}
}

func TestLoad_FromFile(t *testing.T) {
	// Create temporary config file
	tmpDir := t.TempDir()
	cfgFile := filepath.Join(tmpDir, "config.yaml")

	configContent := `
default_model: "anthropic:claude-3-5-sonnet"
cache:
  backend: "disk"
  ttl: "24h"
output:
  dir: "/custom/output"
  format: "json"
log:
  level: "debug"
`

	if err := os.WriteFile(cfgFile, []byte(configContent), 0644); err != nil {
		t.Fatalf("Failed to write config file: %v", err)
	}

	cfg, err := Load(cfgFile)
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.DefaultModel != "anthropic:claude-3-5-sonnet" {
		t.Errorf("DefaultModel = %q, want %q", cfg.DefaultModel, "anthropic:claude-3-5-sonnet")
	}

	if cfg.Cache.Backend != "disk" {
		t.Errorf("Cache.Backend = %q, want %q", cfg.Cache.Backend, "disk")
	}

	if cfg.Cache.TTL != 24*time.Hour {
		t.Errorf("Cache.TTL = %v, want %v", cfg.Cache.TTL, 24*time.Hour)
	}

	if cfg.Output.Dir != "/custom/output" {
		t.Errorf("Output.Dir = %q, want %q", cfg.Output.Dir, "/custom/output")
	}

	if cfg.Output.Format != "json" {
		t.Errorf("Output.Format = %q, want %q", cfg.Output.Format, "json")
	}

	if cfg.Log.Level != "debug" {
		t.Errorf("Log.Level = %q, want %q", cfg.Log.Level, "debug")
	}
}

func TestResolveAPIKeys(t *testing.T) {
	// Set API key environment variables
	os.Setenv("OPENAI_API_KEY", "sk-test-openai")
	os.Setenv("ANTHROPIC_API_KEY", "sk-ant-test-anthropic")
	os.Setenv("GOOGLE_API_KEY", "test-google")
	defer func() {
		os.Unsetenv("OPENAI_API_KEY")
		os.Unsetenv("ANTHROPIC_API_KEY")
		os.Unsetenv("GOOGLE_API_KEY")
	}()

	cfg, err := Load("")
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Providers.OpenAI.APIKey != "sk-test-openai" {
		t.Errorf("OpenAI.APIKey = %q, want %q", cfg.Providers.OpenAI.APIKey, "sk-test-openai")
	}

	if cfg.Providers.Anthropic.APIKey != "sk-ant-test-anthropic" {
		t.Errorf("Anthropic.APIKey = %q, want %q", cfg.Providers.Anthropic.APIKey, "sk-ant-test-anthropic")
	}

	if cfg.Providers.Google.APIKey != "test-google" {
		t.Errorf("Google.APIKey = %q, want %q", cfg.Providers.Google.APIKey, "test-google")
	}
}

func TestValidate(t *testing.T) {
	tests := []struct {
		name    string
		config  Config
		wantErr bool
	}{
		{
			name: "valid config",
			config: Config{
				Cache:  CacheConfig{Backend: "mem"},
				Output: OutputConfig{Format: "markdown"},
				Log:    LogConfig{Level: "info"},
			},
			wantErr: false,
		},
		{
			name: "invalid cache backend",
			config: Config{
				Cache:  CacheConfig{Backend: "invalid"},
				Output: OutputConfig{Format: "markdown"},
				Log:    LogConfig{Level: "info"},
			},
			wantErr: true,
		},
		{
			name: "invalid output format",
			config: Config{
				Cache:  CacheConfig{Backend: "mem"},
				Output: OutputConfig{Format: "invalid"},
				Log:    LogConfig{Level: "info"},
			},
			wantErr: true,
		},
		{
			name: "invalid log level",
			config: Config{
				Cache:  CacheConfig{Backend: "mem"},
				Output: OutputConfig{Format: "markdown"},
				Log:    LogConfig{Level: "invalid"},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestGetProviderAPIKey(t *testing.T) {
	cfg := &Config{
		Providers: ProviderConfigs{
			OpenAI: OpenAIConfig{
				APIKey: "sk-openai-test",
			},
			Anthropic: AnthropicConfig{
				APIKey: "sk-ant-test",
			},
			Google: GoogleConfig{
				APIKey: "google-test",
			},
		},
	}

	tests := []struct {
		provider string
		want     string
	}{
		{"openai", "sk-openai-test"},
		{"anthropic", "sk-ant-test"},
		{"google", "google-test"},
		{"unknown", ""},
	}

	for _, tt := range tests {
		t.Run(tt.provider, func(t *testing.T) {
			got := cfg.GetProviderAPIKey(tt.provider)
			if got != tt.want {
				t.Errorf("GetProviderAPIKey(%q) = %q, want %q", tt.provider, got, tt.want)
			}
		})
	}
}

func TestHasProviderAPIKey(t *testing.T) {
	cfg := &Config{
		Providers: ProviderConfigs{
			OpenAI: OpenAIConfig{
				APIKey: "sk-openai-test",
			},
			Anthropic: AnthropicConfig{
				APIKey: "",
			},
		},
	}

	tests := []struct {
		provider string
		want     bool
	}{
		{"openai", true},
		{"anthropic", false},
		{"unknown", false},
	}

	for _, tt := range tests {
		t.Run(tt.provider, func(t *testing.T) {
			got := cfg.HasProviderAPIKey(tt.provider)
			if got != tt.want {
				t.Errorf("HasProviderAPIKey(%q) = %v, want %v", tt.provider, got, tt.want)
			}
		})
	}
}

func TestProviderDefaults(t *testing.T) {
	cfg, err := Load("")
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	// OpenAI defaults
	if cfg.Providers.OpenAI.DefaultModel != "gpt-4-turbo" {
		t.Errorf("OpenAI.DefaultModel = %q, want %q", cfg.Providers.OpenAI.DefaultModel, "gpt-4-turbo")
	}
	if cfg.Providers.OpenAI.Timeout != 30*time.Second {
		t.Errorf("OpenAI.Timeout = %v, want %v", cfg.Providers.OpenAI.Timeout, 30*time.Second)
	}

	// Anthropic defaults
	if cfg.Providers.Anthropic.DefaultModel != "claude-3-5-sonnet-20241022" {
		t.Errorf("Anthropic.DefaultModel = %q, want %q", cfg.Providers.Anthropic.DefaultModel, "claude-3-5-sonnet-20241022")
	}
	if cfg.Providers.Anthropic.Timeout != 60*time.Second {
		t.Errorf("Anthropic.Timeout = %v, want %v", cfg.Providers.Anthropic.Timeout, 60*time.Second)
	}

	// Ollama defaults
	if cfg.Providers.Ollama.Host != "http://localhost:11434" {
		t.Errorf("Ollama.Host = %q, want %q", cfg.Providers.Ollama.Host, "http://localhost:11434")
	}
	if cfg.Providers.Ollama.DefaultModel != "llama3.3" {
		t.Errorf("Ollama.DefaultModel = %q, want %q", cfg.Providers.Ollama.DefaultModel, "llama3.3")
	}
}
