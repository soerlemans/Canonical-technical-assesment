package main

import (
	"crypto/rand" // crypto/rand is cryptographically secure (math/rand is not)
	"io/ioutil"
	"log"
	"os"
)

func Shred(t_path string) error {
	// Open the file
	file, err := os.OpenFile(t_path, os.O_RDWR, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	// Get length of the file
	finfo, err := file.Stat()
	if err != nil {
		return err
	}

	// Create a new buffer of the same length
	buffer := make([]byte, finfo.Size())
	for index := 0; index < 3; index++ {
		// Fill the buffer with random values
		_, err = rand.Read(buffer)
		if err != nil {
			return err
		}

		// Rewrite file from the beginning again
		_, err := file.Seek(0, 0)
		if err != nil {
			return err
		}

		_, err = file.Write(buffer)
		if err != nil {
			return err
		}
	}

	os.Remove(t_path)

	return nil
}

func copy_template() (string, error) {
	// We copy the file we want to shred from a template,
	// this is just fluff so that we do not have to create a new file everytime we run the program
	const (
		src = "template.txt"
		dst = "file.txt"
	)

	// Copy template file
	data, err := ioutil.ReadFile(src)
	if err != nil {
		return dst, err
	}

	err = ioutil.WriteFile(dst, data, 0644)
	if err != nil {
		return dst, err
	}

	return dst, nil
}

func check(t_err error) {
	if t_err != nil {
		log.Fatal(t_err)

		os.Exit(1)
	}
}

func main() {
	// Prepare the file we will shred
	path, err := copy_template()
	if err != nil {
		check(err)
	}

	// Shred the file
	err = Shred(path)
	if err != nil {
		check(err)
	}
}
