// Copyright (c) 2014, Ben Morgan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os/exec"
	"strings"
	"time"
)

var (
	entrypoint = flag.String("entrypoint", "/bin/sh -c", "command with which to run lines")
	listenAddr = flag.String("listen", "localhost:4000", "what address to listen on")
	timeout    = flag.Uint("timeout", 1000, "close the connection after not receiving for this many milliseconds")
)

func main() {
	flag.Parse()

	log.Println("Listening on", *listenAddr)
	ln, err := net.Listen("tcp", *listenAddr)
	if err != nil {
		log.Fatal(err)
	}
	for {
		cn, err := ln.Accept()
		if err != nil {
			log.Fatal(err)
		}
		go srvcmd(cn)
	}
}

// srvcmd runs as a command whatever the connection reads.
func srvcmd(cn net.Conn) {
	defer cn.Close()

	sc := bufio.NewScanner(cn)
	for scanTimeout(cn, sc) {
		err := runcmd(sc.Text(), cn)
		if err != nil {
			log.Println("Error:", err)
			fmt.Fprintln(cn, "Error:", err)
		}
	}
	if err := sc.Err(); err != nil {
		if nerr, ok := err.(net.Error); ok && nerr.Timeout() {
			log.Printf("Warning: %s read timeout; closing connection", cn.RemoteAddr())
			return
		}
		log.Println("Error:", err)
	}
}

// runcmd runs the command in line through the entrypoint
func runcmd(line string, w io.Writer) error {
	log.Printf("Executing %s %q\n", *entrypoint, line)
	fields := strings.Fields(*entrypoint)
	fields = append(fields, line)
	cmd := exec.Command(fields[0], fields[1:]...)
	cmd.Stdout = w
	cmd.Stderr = w
	return cmd.Run()
}

// scanTimeout scans with a bufio.Scanner, but takes timeout into account.
// If after timeout milliseconds nothing has been read, then the scan fails.
func scanTimeout(cn net.Conn, sc *bufio.Scanner) bool {
	if *timeout > 0 {
		cn.SetReadDeadline(time.Now().Add(time.Duration(*timeout) * time.Millisecond))
	}
	return sc.Scan()
}
