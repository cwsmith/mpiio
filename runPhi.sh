#!/bin/bash
export MIC_MY_NSLOTS=2
export MIC_PPN=2
ibrun.symm -m ./helloIoWorld
