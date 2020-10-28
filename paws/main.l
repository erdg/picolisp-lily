(load
   "../pond.l"
   "db.l"
   "@lib/http.l"
   "@lib/xhtml.l"
   "app.l" )

### main program api
#
# switch - switch to a new project (and create if it does not exist)
# projects - list existing projects (organized as db per project)
# music - list +MusicObjs in project

## +MusicObj methods
#
# rename> - rename obj
# work> - edit obj and update app
#
# and more - see "db.l"

# each project is a directory, with a db file and +Blob's
(de switch (Name)
   (let (Pool (pack "db/" Name "/" Name ".db")
         Blob (pack "db/" Name "/") )
      (setq
         *Pool Pool
         *Blob Blob )
      (call "mkdir" "-p" *Blob)
      (pool *Pool) ) )

(de projects () (chdir "db/" (dir)))

(de music ()
   (make
      (for Obj (collect 'id '+MusicObj)
         (link
            (list Obj (if (; Obj nm) @)) ) ) ) )

(de tracks ()
   (filter
      '((S) (= "wav" (pack (last (split (chop S) ".")))))
      (chdir *Blob (dir)) ) )

(de track-info (Track)
   (and
      (chdir *Blob
         (in (list 'soxi Track)
            (make
               (until (eof)
                  (link (line T)) ) ) ) )
      (clip @)
      (head 6 @)
      (remove 5 @)   # 'duration' is special
      (mapcar '((S) (split (chop S) ":")) @)
      (mapcar last @)
      (mapcar clip @)
      (mapcar pack @)
      ) )


# init stuff
(setq
   *Pool "db/test/test.db"
   *Blob "db/test/" )

(de main ()
   (call "mkdir" "-p" *Blob)
   (pool *Pool *Dbs)
   # load +MusicObj's
   (for Obj (collect 'id '+MusicObj) (load (blob Obj 'l))) )

(de go () (server 8080 "!work"))

### utils

# returns blob subdirectory
# (blobDir '{A1}) -> "db/blob/A/"
# (blobDir '{2}) -> "db/blob/"
(de blobDir (Obj)
   (pack
      (glue "/"
         (filter '((X) (not (num? (any (car X)))))
            (split (chop (blob Obj)) "/") ) )
      "/" ) )

# returns fn from +MusicObj
(de blobFn (Obj)
   (and (blobDir Obj)
      (chop @)
      (split @ "/" ".")
      (pack (cdr @) "%" (; Obj id))
      (any @) ) )  # -> e.g. test%1 (project%id)

