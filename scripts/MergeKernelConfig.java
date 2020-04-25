import java.io.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/*
 * Copyright (c) 2020, Chuck <fanck0605@qq.com>
 *
 * 警告:对着屏幕的哥们,我们允许你使用此脚本，但不允许你抹去作者的信息,请保留这段话。
 */
public class MergeKernelConfig {
    public static void main(String[] args) throws IOException {
        // config from lean's kernel 4.14
        String leanConfig = toString(new InputStreamReader(new FileInputStream("lean_config")));
        // config from rockchip's kernel 5.4
        BufferedReader rkConfig = new BufferedReader(new InputStreamReader(new FileInputStream("rk_config")));
        Writer writer = new OutputStreamWriter(new FileOutputStream("target_config"));
        Pattern isNotSetPattern = Pattern.compile("^# (.*?) is not set$");
        String line;
        while ((line = rkConfig.readLine()) != null) {
            Matcher isNotSet = isNotSetPattern.matcher(line);
            if (isNotSet.find()) {
                String whoIsNotSet = isNotSet.group(1);
                Matcher configFromLean = Pattern.compile("\n(" + whoIsNotSet + "=.*?)\n").matcher(leanConfig);
                if (configFromLean.find()) {
                    writer.write(configFromLean.group(1) + "\n");
                } else {
                    System.out.println(line);
                    writer.write(line + "\n");
                }
            } else {
                writer.write(line + "\n");
            }
        }
        // 别忘了 flush 。。 丢数据了哈
        writer.flush();
        writer.close();
    }

    // from apache IOUtils
    public static String toString(final InputStreamReader reader) throws IOException {
        final StringBuilder builder = new StringBuilder();
        final char[] buf = new char[1024];
        int n;
        while ((n = reader.read(buf)) != -1) {
            builder.append(buf, 0, n);
        }
        return builder.toString();
    }
}
