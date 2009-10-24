/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <endian.h>
#include <cfcard.h>
#include <console.h>
#include <cffat.h>

struct partition_descriptor {
	unsigned char flags;
	unsigned char start_head;
	unsigned short start_cylinder;
	unsigned char type;
	unsigned char end_head;
	unsigned short end_cylinder;
	unsigned int start_sector;
	unsigned int end_sector;
} __attribute__((packed));

struct firstsector {
	unsigned char bootsector[446];
	struct partition_descriptor partitions[4];
	unsigned char signature[2];
} __attribute__((packed));


struct fat16_firstsector {
	/* Common to FATxx */
	char jmp[3];
	char oem[8];
	unsigned short bytes_per_sector;
	unsigned char sectors_per_cluster;
	unsigned short reserved_sectors;
	unsigned char number_of_fat;
	unsigned short max_root_entries;
	unsigned short total_sectors_short;
	unsigned char media_descriptor;
	unsigned short sectors_per_fat;
	unsigned short sectors_per_track;
	unsigned short head_count;
	unsigned int hidden_sectors;
	unsigned int total_sectors;
	
	/* FAT16 specific */
	unsigned char drive_nr;
	unsigned char reserved;
	unsigned char ext_boot_signature;
	unsigned int id;
	unsigned char volume_label[11];
	unsigned char fstype[8];
	unsigned char bootcode[448];
	unsigned char signature[2];
} __attribute__((packed));

struct directory_entry {
	unsigned char filename[8];
	unsigned char extension[3];
	unsigned char attributes;
	unsigned char reserved;
	unsigned char create_time_ms;
	unsigned short create_time;
	unsigned short create_date;
	unsigned short last_access;
	unsigned short ea_index;
	unsigned short lastm_time;
	unsigned short lastm_date;
	unsigned short first_cluster;
	unsigned int file_size;
} __attribute__((packed));

struct directory_entry_lfn {
	unsigned char seq;
	unsigned short name1[5]; /* UTF16 */
	unsigned char attributes;
	unsigned char reserved;
	unsigned char checksum;
	unsigned short name2[6];
	unsigned short first_cluster;
	unsigned short name3[2];
} __attribute__((packed));

#define PARTITION_TYPE_FAT16		0x06
#define PARTITION_TYPE_FAT32		0x0b

static int cffat_partition_start_sector;	/* Sector# of the beginning of the FAT16 partition */

static int cffat_sectors_per_cluster;
static int cffat_fat_sector;			/* Sector of the first FAT */
static int cffat_fat_entries;			/* Number of entries in the FAT */
static int cffat_max_root_entries;
static int cffat_root_table_sector;		/* Sector# of the beginning of the root table */

static int cffat_fat_cached_sector;
static unsigned short int cffat_fat_sector_cache[CF_BLOCK_SIZE/2];

static int cffat_dir_cached_sector;
static struct directory_entry cffat_dir_sector_cache[CF_BLOCK_SIZE/sizeof(struct directory_entry)];

static int cffat_data_start_sector;

int cffat_init()
{
	struct firstsector s0;
	struct fat16_firstsector s;
	int i;
	
	if(!cf_init()) {
		printf("E: Unable to initialize CF card driver\n");
		return 0;
	}
	
	/* Read sector 0, with partition table */
	if(!cf_readblock(0, (void *)&s0)) {
		printf("E: Unable to read block 0\n");
		return 0;
	}
	
	cffat_partition_start_sector = -1;
	for(i=0;i<4;i++)
		if((s0.partitions[i].type == PARTITION_TYPE_FAT16)
		 ||(s0.partitions[i].type == PARTITION_TYPE_FAT32)){
			/*printf("I: Using partition #%d: start sector %08x, end sector %08x\n", i,
				le32toh(s0.partitions[i].start_sector), le32toh(s0.partitions[i].end_sector));*/
			cffat_partition_start_sector = le32toh(s0.partitions[i].start_sector);
			break;
		}
	if(cffat_partition_start_sector == -1) {
		printf("E: No FAT partition was found\n");
		return 0;
	}
	
	/* Read first FAT16 sector */
	if(!cf_readblock(cffat_partition_start_sector, (void *)&s)) {
		printf("E: Unable to read first FAT sector\n");
		return 0;
	}
	
	s.volume_label[10] = 0;
	//printf("I: Volume label: %s\n", s.volume_label);
	
	if(le16toh(s.bytes_per_sector) != CF_BLOCK_SIZE) return 0;
	cffat_sectors_per_cluster = s.sectors_per_cluster;
	
	cffat_fat_entries = (le16toh(s.sectors_per_fat)*CF_BLOCK_SIZE)/2;
	cffat_fat_sector = cffat_partition_start_sector + 1;
	cffat_fat_cached_sector = -1;
	
	cffat_max_root_entries = le16toh(s.max_root_entries);
	cffat_root_table_sector = cffat_fat_sector + s.number_of_fat*le16toh(s.sectors_per_fat);
	cffat_dir_cached_sector = -1;
	
	cffat_data_start_sector = cffat_root_table_sector + (cffat_max_root_entries*sizeof(struct directory_entry))/CF_BLOCK_SIZE;
	
	/*printf("I: Cluster is %d sectors, FAT has %d entries, FAT 1 is at sector %d,\nI: root table is at sector %d (max %d), data is at sector %d\n",
		cffat_sectors_per_cluster, cffat_fat_entries, cffat_fat_sector,
		cffat_root_table_sector, cffat_max_root_entries,
		cffat_data_start_sector);*/
	return 1;
}

static int cffat_read_fat(int offset)
{
	int wanted_sector;
	
	if((offset < 0) || (offset >= cffat_fat_entries))
		return -1;
		
	wanted_sector = cffat_fat_sector + (offset*2)/CF_BLOCK_SIZE;
	if(wanted_sector != cffat_fat_cached_sector) {
		if(!cf_readblock(wanted_sector, (void *)&cffat_fat_sector_cache)) {
			printf("E: CF failed (FAT), sector %d\n", wanted_sector);
			return -1;
		}
		cffat_fat_cached_sector = wanted_sector;
	}
	
	return le16toh(cffat_fat_sector_cache[offset % (CF_BLOCK_SIZE/2)]);
}

static const struct directory_entry *cffat_read_root_directory(int offset)
{
	int wanted_sector;
	
	if((offset < 0) || (offset >= cffat_max_root_entries))
		return NULL;

	wanted_sector = cffat_root_table_sector + (offset*sizeof(struct directory_entry))/CF_BLOCK_SIZE;

	if(wanted_sector != cffat_dir_cached_sector) {
		if(!cf_readblock(wanted_sector, (void *)&cffat_dir_sector_cache)) {
			printf("E: CF failed (Rootdir), sector %d\n", wanted_sector);
			return NULL;
		}
		cffat_dir_cached_sector = wanted_sector;
	}
	return &cffat_dir_sector_cache[offset % (CF_BLOCK_SIZE/sizeof(struct directory_entry))];
}

static void lfn_to_ascii(const struct directory_entry_lfn *entry, char *name, int terminate)
{
	int i;
	unsigned short c;

	for(i=0;i<5;i++) {
		c = le16toh(entry->name1[i]);
		if(c <= 255) {
			*name = c;
			name++;
			if(c == 0) return;
		}
	}
	for(i=0;i<6;i++) {
		c = le16toh(entry->name2[i]);
		if(c <= 255) {
			*name = c;
			name++;
			if(c == 0) return;
		}
	}
	for(i=0;i<2;i++) {
		c = le16toh(entry->name3[i]);
		if(c <= 255) {
			*name = c;
			name++;
			if(c == 0) return;
		}
	}

	if(terminate)
		*name = 0;
}

static int cffat_is_regular(const struct directory_entry *entry)
{
	return ((entry->attributes & 0x10) == 0)
		&& ((entry->attributes & 0x08) == 0)
		&& (entry->filename[0] != 0xe5);
}

int cffat_list_files(cffat_dir_callback cb, void *param)
{
	const struct directory_entry *entry;
	char fmtbuf[8+1+3+1];
	char longname[131];
	int has_longname;
	int i, j, k;

	has_longname = 0;
	longname[sizeof(longname)-1] = 0; /* avoid crashing when reading a corrupt FS */
	for(k=0;k<cffat_max_root_entries;k++) {
		entry = cffat_read_root_directory(k);
		if(entry->attributes == 0x0f) {
			const struct directory_entry_lfn *entry_lfn;
			unsigned char frag;
			int terminate;

			entry_lfn = (const struct directory_entry_lfn *)entry;
			frag = entry_lfn->seq & 0x3f;
			terminate = entry_lfn->seq & 0x40;
			if(frag*13 < sizeof(longname)) {
				lfn_to_ascii((const struct directory_entry_lfn *)entry, &longname[(frag-1)*13], terminate);
				if(frag == 1) has_longname = 1;
			}
			continue;
		} else {
			if(!cffat_is_regular(entry)) {
				has_longname = 0;
				continue;
			}
		}
		if(entry == NULL) return 0;
		if(entry->filename[0] == 0) {
			has_longname = 0;
			break;
		}
		j = 0;
		for(i=0;i<8;i++) {
			if(entry->filename[i] == ' ') break;
			fmtbuf[j++] = entry->filename[i];
		}
		fmtbuf[j++] = '.';
		for(i=0;i<3;i++) {
			if(entry->extension[i] == ' ') break;
			fmtbuf[j++] = entry->extension[i];
		}
		fmtbuf[j++] = 0;
		if(!cb(fmtbuf, has_longname ? longname : fmtbuf, param)) return 0;
		has_longname = 0;
	}
	return 1;
}

static const struct directory_entry *cffat_find_file_by_name(const char *filename)
{
	char searched_filename[8];
	char searched_extension[3];
	char *dot;
	const char *c;
	int i;
	const struct directory_entry *entry;
	
	dot = strrchr(filename, '.');
	if(dot == NULL)
		return NULL;
	
	memset(searched_filename, ' ', 8);
	memset(searched_extension, ' ', 3);
	i = 0;
	for(c=filename;c<dot;c++)
		searched_filename[i++] = toupper(*c);
		
	i = 0;
	for(c=dot+1;*c!=0;c++)
		searched_extension[i++] = toupper(*c);
		
	for(i=0;i<cffat_max_root_entries;i++) {
		entry = cffat_read_root_directory(i);
		if(entry == NULL) break;
		if(entry->filename[0] == 0) break;
		if(!cffat_is_regular(entry)) continue;
		if(!memcmp(searched_filename, entry->filename, 8)
		 &&!memcmp(searched_extension, entry->extension, 3))
		 	return entry;
	}
	return NULL;
}

static int cffat_load_cluster(int clustern, char *buffer, int maxsectors)
{
	int startsector;
	int i;
	int toread;
	
	clustern = clustern - 2;
	startsector = cffat_data_start_sector + clustern*cffat_sectors_per_cluster;
	if(maxsectors < cffat_sectors_per_cluster)
		toread = maxsectors;
	else
		toread = cffat_sectors_per_cluster;
	for(i=0;i<toread;i++)
		if(!cf_readblock(startsector+i, (unsigned char *)buffer+i*CF_BLOCK_SIZE)) {
			printf("E: CF failed (Cluster), sector %d\n", startsector+i);
			return 0;
		}
	return 1;
}

int cffat_load(const char *filename, char *buffer, int size, int *realsize)
{
	const struct directory_entry *entry;
	int cluster_size;
	int cluster;
	int n;
	
	cluster_size = cffat_sectors_per_cluster*CF_BLOCK_SIZE;
	size /= CF_BLOCK_SIZE;
	
	entry = cffat_find_file_by_name(filename);
	if(entry == NULL) {
		printf("E: File not found: %s\n", filename);
		return 0;
	}
	
	if(realsize != NULL) *realsize = le32toh(entry->file_size);
	
	n = 0;
	cluster = le16toh(entry->first_cluster);
	while(size > 0) {
		if(!cffat_load_cluster(cluster, buffer+n*cluster_size, size))
			return 0;
		size -= cffat_sectors_per_cluster;
		n++;
		cluster = cffat_read_fat(cluster);
		if(cluster >= 0xFFF8) break;
		if(cluster == -1) return 0;
	}
	//putsnonl("\n");
	
	return n*cluster_size;
}

void cffat_done()
{
	cf_done();
}
