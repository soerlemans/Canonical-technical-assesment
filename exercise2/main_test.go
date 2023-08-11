package main

import (
	"errors"
	"io/fs"
	"os"
	"testing"
)

func TestStandardUsage(t *testing.T) {
	path, err := copy_template()
	if err != nil {
		t.Errorf("Failed to copy template file: %q", err)
	}

	err = Shred(path)
	if err != nil {
		t.Errorf("Failed to shred (%q): %q", path, err)
	}

	_, err = os.Stat(path)
	if !os.IsNotExist(err) {
		t.Errorf("%q still exists: %q", path, err)
	}
}

func TestNonExistentFile(t *testing.T) {
	err := Shred("non_existent_file.txt")
	if !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("Expected fs.ErrNotExist got: %q", err)
	}
}

func TestWrongPermissions(t *testing.T) {
	err := Shred("wrong_permissions.txt")
	if !errors.Is(err, fs.ErrPermission) {
		t.Errorf("Expected fs.ErrPermission got: %q", err)
	}
}
