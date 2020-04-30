# f_readdir 在使用长文件名时的问题

[TOC]

## 结论先行

FRESULT f_readdir (DIR* dp, FILINFO* fno)

在使用了长文件名后，在操作f_readdir前，需要初始化fno.lfsize

```c
    FILINFO info;
    TCHAR name[64];
    int res;
    DIR file_dir;

    info.lfname = name;
    info.lfsize = 64;  //init lfsize

    f_opendir(&file_dir, PICTURE_FILE_DIR);
    f_readdir(&file_dir, &info);
```

## 分析过程

在使能了长文件名后，通过f_readdir遍历目录下的文件，发现获取到的lfname为空，代码如下

```text
[DBG]-[NORMAL]\USER\main.c\list_for_each_pic\read dir, res=0, fname=PIC201~1.BMP, lfname=
[DBG]-[NORMAL]\USER\main.c\list_for_each_pic\read dir, res=0, fname=PIC201~2.BMP, lfname=
[DBG]-[NORMAL]\USER\main.c\list_for_each_pic\read dir, res=0, fname=PIC201~3.BMP, lfname=
```

```c
static void list_for_each_pic(char *debug)
{
    FILINFO info;
    TCHAR name[64];
    int res;
    DIR file_dir;

    info.lfname = name;

    DBG_TO_SERIAL(DBG_NORMAL, "%s", debug);

    res = f_opendir(&file_dir, PICTURE_FILE_DIR);
    if (res) {
        DBG_TO_SERIAL(DBG_NORMAL, "can not open dir:%s, res=%d", PICTURE_FILE_DIR, res);
        my_msg.sf_lock = 0;
        return;
    }

    /* read picture file */
    while (1) {
        res = f_readdir(&file_dir, &info);
        DBG_TO_SERIAL(DBG_NORMAL, "read dir, res=%d, fname=%s, lfname=%s", res, info.fname, info.lfname);
        if (res || info.fname[0] == 0)
            break;
        if (info.fname[0] == '.')
            continue;
    }
    f_closedir(&file_dir);
}
```

追踪fatfs代码，发现有如下机制

```c
if (dp->sect && fno->lfsize && dp->lfn_idx != 0xFFFF) {	/* Get LFN if available */
```

通过添加打印，发现出现获取不到lfname时的lfzise为0

```c
/*-----------------------------------------------------------------------*/
/* Get file information from directory entry                             */
/*-----------------------------------------------------------------------*/
#if _FS_MINIMIZE <= 1 || _FS_RPATH >= 2
static
void get_fileinfo (     /* No return code */
    DIR* dp,        /* Pointer to the directory object */
    FILINFO* fno        /* Pointer to the file information to be filled */
)
{
    UINT i;
    TCHAR *p, c;
    BYTE *dir;
#if _USE_LFN
    WCHAR w, *lfn;
#endif

    p = fno->fname;
    if (dp->sect) {     /* Get SFN */
        dir = dp->dir;
        i = 0;
        while (i < 11) {        /* Copy name body and extension */
            c = (TCHAR)dir[i++];
            if (c == ' ') continue;         /* Skip padding spaces */
            if (c == RDDEM) c = (TCHAR)DDEM;    /* Restore replaced DDEM character */
            if (i == 9) *p++ = '.';         /* Insert a . if extension is exist */
#if _USE_LFN
            if (IsUpper(c) && (dir[DIR_NTres] & (i >= 9 ? NS_EXT : NS_BODY)))
                c += 0x20;          /* To lower */
#if _LFN_UNICODE
        if (IsDBCS1(c) && i != 8 && i != 11 && IsDBCS2(dir[i]))
            c = c << 8 | dir[i++];
        c = ff_convert(c, 1);	/* OEM -> Unicode */
        if (!c) c = '?';
#endif
#endif
            *p++ = c;
        }
        fno->fattrib = dir[DIR_Attr];				/* Attribute */
        fno->fsize = LD_DWORD(dir + DIR_FileSize);	/* Size */
        fno->fdate = LD_WORD(dir + DIR_WrtDate);	/* Date */
        fno->ftime = LD_WORD(dir + DIR_WrtTime);	/* Time */
    }
    *p = 0;		/* Terminate SFN string by a \0 */

#if _USE_LFN
    if (fno->lfname) {
        i = 0; p = fno->lfname;
        if (dp->sect && fno->lfsize && dp->lfn_idx != 0xFFFF) {	/* Get LFN if available */
            lfn = dp->lfn;
            while ((w = *lfn++) != 0) {		/* Get an LFN character */
#if !_LFN_UNICODE
                w = ff_convert(w, 0);		/* Unicode -> OEM */
                if (!w) { i = 0; break; }	/* No LFN if it could not be converted */
                if (_DF1S && w >= 0x100)	/* Put 1st byte if it is a DBC (always false on SBCS cfg) */
                    p[i++] = (TCHAR)(w >> 8);
#endif
                if (i >= fno->lfsize - 1) { i = 0; break; }	/* No LFN if buffer overflow */
                p[i++] = (TCHAR)w;
            }
        }
        p[i] = 0;	/* Terminate LFN string by a \0 */
    }
#endif
}
#endif /* _FS_MINIMIZE <= 1 || _FS_RPATH >= 2 */



/*-----------------------------------------------------------------------*/
/* Read Directory Entries in Sequence                                    */
/*-----------------------------------------------------------------------*/

FRESULT f_readdir (
    DIR* dp,			/* Pointer to the open directory object */
    FILINFO* fno		/* Pointer to file information to return */
)
{
    FRESULT res;
    DEFINE_NAMEBUF;


    res = validate(dp);						/* Check validity of the object */
    if (res == FR_OK) {
        if (!fno) {
            res = dir_sdi(dp, 0);			/* Rewind the directory object */
        } else {
            INIT_BUF(*dp);
            res = dir_read(dp, 0);			/* Read an item */
            if (res == FR_NO_FILE) {		/* Reached end of directory */
                dp->sect = 0;
                res = FR_OK;
            }
            if (res == FR_OK) {				/* A valid entry is found */
                get_fileinfo(dp, fno);		/* Get the object information */
                res = dir_next(dp, 0);		/* Increment index for next */
                if (res == FR_NO_FILE) {
                    dp->sect = 0;
                    res = FR_OK;
                }
            }
            FREE_BUF();
        }
    }

    LEAVE_FF(dp->fs, res);
}
```

对lfsize进行搜索，看在什么位置进行的赋值

```c
Ff.c (\fat_fs\src):	if (fno->lfname && fno->lfsize) {
Ff.c (\fat_fs\src):				if (i >= fno->lfsize - 1) { i = 0; break; }	/* Buffer overflow, no LFN */
Ff.c (\fat_fs\src):			fno.lfsize = i;
Ff.h (\fat_fs\inc):	UINT 	lfsize;			/* Size of LFN buffer in TCHAR */
```

发现其实没有任何位置对此变量进行赋值

```c

#if _FS_RPATH >= 2
FRESULT f_getcwd (
    TCHAR *path,	/* Pointer to the directory path */
    UINT sz_path	/* Size of path */
)
{
    FRESULT res;
    DIR dj;
    UINT i, n;
    DWORD ccl;
    TCHAR *tp;
    FILINFO fno;
    DEF_NAMEBUF;


    *path = 0;
    res = chk_mounted((const TCHAR**)&path, &dj.fs, 0);	/* Get current volume */
    if (res == FR_OK) {
        INIT_BUF(dj);
        i = sz_path;		/* Bottom of buffer (dir stack base) */
        dj.sclust = dj.fs->cdir;			/* Start to follow upper dir from current dir */
        while ((ccl = dj.sclust) != 0) {	/* Repeat while current dir is a sub-dir */
            res = dir_sdi(&dj, 1);			/* Get parent dir */
            if (res != FR_OK) break;
            res = dir_read(&dj);
            if (res != FR_OK) break;
            dj.sclust = LD_CLUST(dj.dir);	/* Goto parent dir */
            res = dir_sdi(&dj, 0);
            if (res != FR_OK) break;
            do {							/* Find the entry links to the child dir */
                res = dir_read(&dj);
                if (res != FR_OK) break;
                if (ccl == LD_CLUST(dj.dir)) break;	/* Found the entry */
                res = dir_next(&dj, 0);	
            } while (res == FR_OK);
            if (res == FR_NO_FILE) res = FR_INT_ERR;/* It cannot be 'not found'. */
            if (res != FR_OK) break;
#if _USE_LFN
            fno.lfname = path;
            fno.lfsize = i;
#endif
            get_fileinfo(&dj, &fno);		/* Get the dir name and push it to the buffer */
            tp = fno.fname;
            if (_USE_LFN && *path) tp = path;
            for (n = 0; tp[n]; n++) ;
            if (i < n + 3) {
                res = FR_NOT_ENOUGH_CORE; break;
            }
            while (n) path[--i] = tp[--n];
            path[--i] = '/';
        }
        tp = path;
        if (res == FR_OK) {
            *tp++ = '0' + CurrVol;			/* Put drive number */
            *tp++ = ':';
            if (i == sz_path) {				/* Root-dir */
                *tp++ = '/';
            } else {						/* Sub-dir */
                do		/* Add stacked path str */
                    *tp++ = path[i++];
                while (i < sz_path);
            }
        }
        *tp = 0;
        FREE_BUF();
    }

    LEAVE_FF(dj.fs, res);
}
#endif /* _FS_RPATH >= 2 */
#endif /* _FS_RPATH >= 1 */
```

## 结论

```c
// lfsize仅有一个作用，就是用来限制i，防止内存越界，lfsize需要在使用f_readdir之前自己手动赋值

#if _USE_LFN
    if (fno->lfname) {
        i = 0; p = fno->lfname;
        if (dp->sect && fno->lfsize && dp->lfn_idx != 0xFFFF) {	/* Get LFN if available */
            lfn = dp->lfn;
            while ((w = *lfn++) != 0) {		/* Get an LFN character */
#if !_LFN_UNICODE
                w = ff_convert(w, 0);		/* Unicode -> OEM */
                if (!w) { i = 0; break; }	/* No LFN if it could not be converted */
                if (_DF1S && w >= 0x100)	/* Put 1st byte if it is a DBC (always false on SBCS cfg) */
                    p[i++] = (TCHAR)(w >> 8);
#endif
                if (i >= fno->lfsize - 1) { i = 0; break; }	/* No LFN if buffer overflow */
                p[i++] = (TCHAR)w;
            }
        }
        p[i] = 0;	/* Terminate LFN string by a \0 */
    }
#endif
```
