import java.nio.file.*;
class WriteProbe {public static void main(String[] args) throws Exception {Path p=Path.of(args[0]).toAbsolutePath();System.out.println(p);System.out.println("exists="+Files.exists(p.getParent())+" writable="+Files.isWritable(p.getParent()));Files.writeString(p,"build filesystem probe");System.out.println(Files.readString(p));}}
