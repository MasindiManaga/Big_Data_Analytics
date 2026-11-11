package org.itbda.mapreduce;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class KeywordReducer
        extends Reducer<Text, LongWritable, Text, Text> {

    @Override
    protected void reduce(
            Text key,
            Iterable<LongWritable> values,
            Context context)
            throws IOException, InterruptedException {
// collect the column numbers
        List<Long> columns = new ArrayList<>();

        for (LongWritable value : values) {
            columns.add(value.get());
        }

        Collections.sort(columns); // sort the columns
// write the results
        for (Long column : columns) {
            context.write(
                    key,
                    new Text(Long.toString(column)));
        }
    }
}
