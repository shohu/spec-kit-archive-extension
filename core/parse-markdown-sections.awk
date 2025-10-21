#!/usr/bin/awk -f
# parse-markdown-sections.awk
# Parses Markdown into sections based on H2/H3 headings
# Output format: SECTION_START|level|heading_text
#                content lines...
#                SECTION_END

BEGIN {
    in_section = 0
    current_level = 0
    current_heading = ""
    seen_first_section = 0
    preamble_started = 0
}

/^##+ / {
    # Close previous section if exists
    if (in_section) {
        print "SECTION_END"
    } else if (preamble_started) {
        # Close preamble if exists
        print "SECTION_END"
    }
    
    seen_first_section = 1
    
    # Detect heading level
    match($0, /^#+/)
    level = RLENGTH
    
    # Extract heading text (remove leading #'s and spaces)
    heading = $0
    sub(/^#+[ \t]*/, "", heading)
    
    print "SECTION_START|" level "|" heading
    in_section = 1
    current_level = level
    current_heading = heading
    next
}

{
    # Print content lines if in a section
    if (in_section) {
        print
    } else {
        # Before first section (preamble)
        if (!seen_first_section) {
            if (!preamble_started) {
                print "SECTION_START|0|PREAMBLE"
                preamble_started = 1
            }
            print
        }
    }
}

END {
    # Close last section
    if (in_section) {
        print "SECTION_END"
    } else if (preamble_started) {
        print "SECTION_END"
    }
}

