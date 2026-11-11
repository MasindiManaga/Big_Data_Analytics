
package org.itbda.mapreduce;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class KeywordSearchDriver {

    public static void main(String[] args)
            throws Exception {

        if (args.length != 3) {
            System.err.println(
                "Usage: KeywordSearchDriver "
                + "<input> <output> <keyword>");
            System.exit(1);
        }

        Configuration conf = new Configuration();

        conf.set("search.keyword", args[2]);

        Job job = Job.getInstance(
                conf, "Case-insensitive keyword search");

        job.setJarByClass(KeywordSearchDriver.class);

        job.setInputFormatClass(
                WholeFileInputFormat.class);

        job.setMapperClass(KeywordMapper.class);
        job.setReducerClass(KeywordReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(LongWritable.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setNumReduceTasks(1);

        FileInputFormat.addInputPath(
                job, new Path(args[0]));

        FileOutputFormat.setOutputPath(
                job, new Path(args[1]));

        System.exit(
                job.waitForCompletion(true) ? 0 : 1);
    }
}
