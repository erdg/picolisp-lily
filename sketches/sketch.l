(load "../pond.l")

(de new-sketch (Nm)
   (call 'mkdir Nm)
   (let File (pack Nm "/" Nm ".l")
      (out File (prin (pack "(de " Nm " ())")))
      (load File) ) )
