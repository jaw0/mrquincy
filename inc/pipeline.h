/*
  Copyright (c) 2014
  Author: Jeff Weisberg <jaw @ solvemedia.com>
  Created: 2014-Mar-21 16:55 (EDT)
  Function: task pipeline

*/

#ifndef __mrquincy_pipeline_h_
#define __mrquincy_pipeline_h_

class ACPMRMTaskCreate;

class Pipeline {
    int		_pid;
    int		_inpid;
    string	_tmpfile;

    void _cleanup(void);
public:
    Pipeline(const ACPMRMTaskCreate *, int*);
    ~Pipeline();
    int waitpid(void);
    void abort(void);
    void done(void){ _cleanup(); }
    bool still_producing(void);
};


#endif //  __mrquincy_pipeline_h_
