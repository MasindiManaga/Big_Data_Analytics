package org.itbda.mapreduce;

import java.io.IOException;
import java.util.Locale; 
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class KeywordMapper
        extends Mapper<Text, Text, Text, LongWritable> {

    private String keyword;

    @Override
    protected void setup(Context context) {
        keyword = context.getConfiguration()
                .get("search.keyword", "")
                .toLowerCase(Locale.ROOT); // get the keyword from configuration

        if (keyword.isEmpty()) {
            throw new IllegalArgumentException(
                    "Search keyword cannot be empty.");
        }
    }

    @Override
    protected void map(
            Text fileName,
            Text content,
            Context context)
            throws IOException, InterruptedException {

        String[] lines = content.toString()
                .split("\\R", -1);

        for (int row = 0; row < lines.length; row++) {  // get length of lines in the file

            String line = lines[row]
                    .toLowerCase(Locale.ROOT);

            int start = 0;

            while ((start = line.indexOf(
                    keyword, start)) != -1) { // Searches for the keyword in the line

                String location = fileName.toString()
                        + "\t" + (row + 1);

                context.write(
                        new Text(location),
                        new LongWritable(start + 1)); // converts position to 1-based index for output

                start++;
            }
        }
    }
}
