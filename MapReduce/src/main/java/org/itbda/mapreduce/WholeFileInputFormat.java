package org.itbda.mapreduce;

import java.io.IOException;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;

public class WholeFileInputFormat
        extends FileInputFormat<Text, Text> {

    @Override
    protected boolean isSplitable(
            org.apache.hadoop.mapreduce.JobContext context,
            org.apache.hadoop.fs.Path filename) {
        return false;
    }

    @Override
    public RecordReader<Text, Text> createRecordReader(
            InputSplit split,
            TaskAttemptContext context)
            throws IOException, InterruptedException {

        return new WholeFileRecordReader();
    }
}
