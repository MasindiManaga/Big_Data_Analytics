package org.itbda.mapreduce;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

public class WholeFileRecordReader
        extends RecordReader<Text, Text> {

    private FileSplit split;
    private TaskAttemptContext context;
    private boolean processed = false;
    private final Text key = new Text();
    private final Text value = new Text();

    @Override
    public void initialize(
            InputSplit inputSplit,
            TaskAttemptContext taskContext) {

        split = (FileSplit) inputSplit;
        context = taskContext;
    }

    @Override
    public boolean nextKeyValue() throws IOException {

        if (processed) {
            return false;
        }

        long length = split.getLength();

        if (length > Integer.MAX_VALUE) {
            throw new IOException("File exceeds supported size.");
        }

        byte[] bytes = new byte[(int) length];

        FileSystem fs = split.getPath()
                .getFileSystem(context.getConfiguration());

        try (FSDataInputStream stream =
                     fs.open(split.getPath())) {

            stream.readFully(split.getStart(), bytes);
        }

        key.set(split.getPath().getName());
        value.set(new String(bytes, StandardCharsets.UTF_8));

        processed = true;
        return true;
    }

    @Override
    public Text getCurrentKey() {
        return key;
    }

    @Override
    public Text getCurrentValue() {
        return value;
    }

    @Override
    public float getProgress() {
        return processed ? 1.0f : 0.0f;
    }

    @Override
    public void close() {
    }
}
