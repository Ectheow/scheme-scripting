(use-modules (srfi srfi-64)
	     (custom processes)
	     (custom tests common)
	     (ice-9 regex)
	     (ice-9 rdelim))
(test-begin "pipeline-tests")

(test-equal #true
  (pipeline? (exec-pipe '((echo hello) (cat -)) #f #f #f)))

(test-equal "hello"
  (let ([pipeline (exec-pipe '((echo hello) (cat -)) #f #f #f)])
    (flush-all-ports)
    (read-line (pipeline-stdout pipeline))))

(test-equal "hello"
  (let ([pipeline (exec-pipe '((echo hello)
			       (cat -)
			       (cat -)
			       (cat -)
			       (grep .*)) #f #f #f)])
    (flush-all-ports)
    (read-line (pipeline-stdout pipeline))))

(let ([thepipe (exec-pipe '((cat -) (cat -)) #f #f #f)])
  (display "hello\n" (pipeline-stdin thepipe))
  (flush-all-ports)
  (close (pipeline-stdin thepipe))
  (test-equal "hello"
    (read-line (pipeline-stdout thepipe)))
  (test-equal (length (pipeline-close thepipe)) 2))

(let* ([thepipe (exec-pipe '((echo hello)
			    (cat -)
			    (cat -)) #f #f #f)]
       [exits (pipeline-close thepipe)])
  (let loop ([exits exits])
    (cond
     [(null? exits) #t]
     [else
      (test-equal 0 (status:exit-val (cdar exits)))
      (loop (cdr exits))])))

(display "test from input\n")
;; test input from a file.
(let ([name&input-port (get-tmpfile-name&port)])
  (display "hello, world\n" (cdr name&input-port))
  (flush-all-ports)
  (close (cdr name&input-port))
  (let* ([input-file
	  (open-input-file (car name&input-port))]
	 [pipeline (exec-pipe '((cat -) (cat -))
			      #f input-file #f)])
    (test-equal
	"hello, world"
      (begin
	(flush-all-ports)
	(read-line (pipeline-stdout pipeline))))
  (pipeline-close pipeline)))

(display "test closed pipe\n")
;; test output to a file, input from a file.
(let ([name&output-port (get-tmpfile-name&port)]
      [name&input-port (get-tmpfile-name&port)])
  (display "hello, world\n" (cdr name&input-port))
  (flush-all-ports)
  (close (cdr name&input-port))
  (let* ([input-port (open-input-file (car name&input-port))]
	 [pipeline (exec-pipe '((cat -) (cat -))
			      (cdr name&output-port)
			      input-port #f)])
    (pipeline-close pipeline)
    (close (cdr name&output-port)))
  (let ([input-port (open-input-file (car name&output-port))])
    (test-equal
	"hello, world"
      (read-line input-port))))

    
(test-end "pipeline-tests")