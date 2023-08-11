package main

import (
	"errors"
	"io/fs"
	"testing"
)

func setupTest(t *testing.T) string {
	path, err := copy_template()
	if err != nil {
		t.Errorf("Failed to copy template for Test: %q", err)
	}

	return path
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
