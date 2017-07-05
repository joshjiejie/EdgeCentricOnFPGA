class ECP: public CAASBase, public IServiceClient, public ISPLClient
{
public:

   ECP(RuntimeClient * rtc, char *puzName);
   ~ECP();

   btInt run();

   // <ISPLClient>
   virtual void OnTransactionStarted(TransactionID const &TranID,
                                     btVirtAddr AFUDSM,
                                     btWSSize AFUDSMSize);
   virtual void OnContextWorkspaceSet(TransactionID const &TranID);

   virtual void OnTransactionFailed(const IEvent &Event);

   virtual void OnTransactionComplete(TransactionID const &TranID);

   virtual void OnTransactionStopped(TransactionID const &TranID);
   virtual void OnWorkspaceAllocated(TransactionID const &TranID,
                                     btVirtAddr WkspcVirt,
                                     btPhysAddr WkspcPhys,
                                     btWSSize WkspcSize);

   virtual void OnWorkspaceAllocateFailed(const IEvent &Event);

   virtual void OnWorkspaceFreed(TransactionID const &TranID);

   virtual void OnWorkspaceFreeFailed(const IEvent &Event);
   // </ISPLClient>

   // <begin IServiceClient interface>
   virtual void serviceAllocated(IBase *pServiceBase,
                                 TransactionID const &rTranID);

   virtual void serviceAllocateFailed(const IEvent &rEvent);

   virtual void serviceFreed(TransactionID const &rTranID);

   virtual void serviceEvent(const IEvent &rEvent);
   // <end IServiceClient interface>

   /* SW implementation of a ECP solver */
   static void print_board(uint32_t *board);
   static int32_t sudoku_norec(uint32_t *board, uint32_t *os);
   static int32_t check_correct(uint32_t *board, uint32_t *unsolved_pieces);
   static int32_t solve(uint32_t *board, uint32_t *os);
   protected:

   char          *m_puzName;
   IBase         *m_pAALService;    // The generic AAL Service interface for the AFU.
   RuntimeClient *m_runtimClient;
   ISPLAFU       *m_SPLService;
   CSemaphore     m_Sem;            // For synchronizing with the AAL runtime.
   btInt          m_Result;

   // Workspace info
   btVirtAddr     m_pWkspcVirt;     ///< Workspace virtual address.
   btWSSize       m_WkspcSize;      ///< DSM workspace size in bytes.

   btVirtAddr     m_AFUDSMVirt;     ///< Points to DSM
   btWSSize       m_AFUDSMSize;     ///< Length in bytes of DSM
};




/* DBS: for ECP */


void ECP::print_board(uint32_t *board)
{   
   printf("\n");
}

int32_t ECP::check_correct(uint32_t *board, uint32_t *unsolved_pieces)
{   
   return 0;
}

inline uint32_t one_set(uint32_t x)
{
   /* all ones if pow2, otherwise 0 */
   uint32_t pow2 = (x & (x - 1));
   uint32_t m = (pow2 == 0);
   return ((~m) + 1) & x;
}

int32_t ECP::solve(uint32_t *board, uint32_t *os)
{return 0;}

int32_t ECP::sudoku_norec(uint32_t *board, uint32_t *os)
{return 1;}


///////////////////////////////////////////////////////////////////////////////
///
///  Implementation
///
///////////////////////////////////////////////////////////////////////////////
ECP::ECP(RuntimeClient *rtc, char *puzName) :
   m_puzName(puzName),
   m_pAALService(NULL),
   m_runtimClient(rtc),
   m_SPLService(NULL),
   m_Result(0),
   m_pWkspcVirt(NULL),
   m_WkspcSize(0),
   m_AFUDSMVirt(NULL),
   m_AFUDSMSize(0)
{
   SetSubClassInterface(iidServiceClient, dynamic_cast<IServiceClient *>(this));
   SetInterface(iidSPLClient, dynamic_cast<ISPLClient *>(this));
   SetInterface(iidCCIClient, dynamic_cast<ICCIClient *>(this));
   m_Sem.Create(0, 1);
}

ECP::~ECP()
{m_Sem.Destroy();}

btInt ECP::run()
{
   cout <<"======================="<<endl;
   cout <<"= Hello SPL LB Sample ="<<endl;
   cout <<"======================="<<endl;

   // Request our AFU.

   // NOTE: This example is bypassing the Resource Manager's configuration record lookup
   //  mechanism.  This code is work around code and subject to change.
   NamedValueSet Manifest;
   NamedValueSet ConfigRecord;


#if defined( HWAFU )                /* Use FPGA hardware */
   ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME, "libHWSPLAFU");
   ConfigRecord.Add(keyRegAFU_ID,"5DA62813-9A75-4228-8FDB-5D4006DD55CE");
   ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_AIA_NAME, "libAASUAIA");

   #elif defined ( ASEAFU )
   ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME, "libASESPLAFU");
   ConfigRecord.Add(AAL_FACTORY_CREATE_SOFTWARE_SERVICE,true);

#else

   ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME, "libSWSimSPLAFU");
   ConfigRecord.Add(AAL_FACTORY_CREATE_SOFTWARE_SERVICE,true);
#endif

   Manifest.Add(AAL_FACTORY_CREATE_CONFIGRECORD_INCLUDED, ConfigRecord);

   Manifest.Add(AAL_FACTORY_CREATE_SERVICENAME, "Hello SPL LB");

   MSG("Allocating Service");

   // Allocate the Service and allocate the required workspace.
   //   This happens in the background via callbacks (simple state machine).
   //   When everything is set we do the real work here in the main thread.
   m_runtimClient->getRuntime()->allocService(dynamic_cast<IBase *>(this), Manifest);

   m_Sem.Wait();

   // If all went well run test.
   //   NOTE: If not successful we simply bail.
   //         A better design would do all appropriate clean-up.


  int i, j, k, o, p, q;
      //=============================
      // Now we have the NLB Service
      //   now we can use it
      //=============================
      MSG("Running Test");

      btVirtAddr         pWSUsrVirt = m_pWkspcVirt; // Address of Workspace
      const btWSSize     WSLen      = m_WkspcSize; // Length of workspace in bytes

      INFO("Allocated " << WSLen << "-byte Workspace at virtual address "
                        << std::hex << (void *)pWSUsrVirt);

      // Number of bytes in each of the source and destination buffers (4 MiB in this case)
      btUnsigned32bitInt a_num_bytes= (btUnsigned32bitInt) ((WSLen - sizeof(VAFU2_CNTXT)) / 2);
      btUnsigned32bitInt a_num_cl   = a_num_bytes / CL(1);  // number of cache lines in buffer

      // VAFU Context is at the beginning of the buffer
      VAFU2_CNTXT       *pVAFU2_cntxt = reinterpret_cast<VAFU2_CNTXT *>(pWSUsrVirt);

      btVirtAddr         pSource_V = pWSUsrVirt + sizeof(VAFU2_CNTXT);

	  btVirtAddr         pSource_E = pSource_V + 40960 * CL(1);
			
      // The destination buffer is right after the source buffer
      btVirtAddr         pDest   = pSource_E + 627700* CL(1);

      
      omp_set_nested(1); 
      
      int						*LocalUpdateBufferCounter[ThreadNum];
	  int 						**UpdateBufferCache[ThreadNum];
	  	
	  for(i=0; i<ThreadNum; i++){
			LocalUpdateBufferCounter[i] = (int*) malloc(sizeof(int)*P);	
			UpdateBufferCache[i] = (int**) malloc(sizeof(int*)*P);
			for(j=0;	j<P; j++){
				LocalUpdateBufferCounter[i][j]=0;
				UpdateBufferCache[i][j] = (int*) malloc(sizeof(int)*LocalUpdateBufferSize);	
			}
		}
		
      bt32bitInt delay(0.001);   
      
	  int test_source = 2;	
	  int root = 2;
	  int current_level =0;	
	  int call_counter = 15;
	  int interval_id;
	  int FrontierSize = 0;
	  int FPGA_no_of_writes;
	  int counter=0;
	  int have_update=1;
	  volatile bt32bitInt done = 0;
	  
	  //------------------------------------------------------------------
	  // read files and initialization
	  interval* 		Intervals 	= (interval*) malloc(sizeof(interval)*P);		
	  vertex* 			vertex_set 	= (vertex*) malloc(sizeof(vertex)*P*I);   // this set is only used by cpu
	  
	  for(i=0; i<P*I; i++){
		vertex_set[i].offset = 0;
		vertex_set[i].count = 0;
	  }
	  
	   ::memset( pSource_V, 	0xff,  	40960*CL(1) );
      ::memset( pDest,   			0x00, 	320000*CL(1) );      	         
      *((unsigned char*)(pSource_V)+root) = current_level;
	  	for(i=0; i<40960; i++){	  		 		 
		 	*((unsigned short*)(pSource_V)+31+32*i) = (*((unsigned short*)(pSource_V)+31+32*i) & CL_ID_MASK) + ((i&4095)<<4);
		} 
	  
	 	 FILE *fp;  unsigned int u1, u2;
			
		if ((fp=fopen(FILE_NAME,"r"))==NULL) printf("Cannot open file. Check the name.\n"); 
		else {
			if(fscanf(fp,"%d %d\n",&u1,&u2)!=EOF){				
					*((unsigned int*)(pSource_E)+1) = u1;
					*((unsigned int*)(pSource_E)+0) = u2;					
			}
			for(i=1; i<E; i++){
				if(fscanf(fp,"%d %d\n",&u1,&u2)!=EOF){
					*((unsigned int*)(pSource_E)+i*2+1)=u1;			// source 
					*((unsigned int*)(pSource_E)+i*2+0)=u2;         // destination 																																				
				}
				if(*((unsigned int*)(pSource_E)+i*2+1) != *((unsigned int*)(pSource_E)+(i-1)*2+1)){
					vertex_set[*((unsigned int*)(pSource_E)+i*2+1)].offset = i;	
					vertex_set[*((unsigned int*)(pSource_E)+(i-1)*2+1)].count=counter+1;
					counter=0;
				} else{
					counter++;
				}
			}
			fclose(fp);
		}
		
		for(i=0; i<P; i++){
			for(j=I*i; j<(i+1)*I-1; j++){
				if(vertex_set[j].count !=0) {
						Intervals[i].edge_end_offset = vertex_set[j].offset+vertex_set[j].count;
						Intervals[i].edge_end_cl = Intervals[i].edge_end_offset/8;		
				}		
			}	
			for(j=(i+1)*I-1; j>i*I; j--){
				if(vertex_set[j].count !=0) {
						Intervals[i].edge_start_offset = vertex_set[j].offset;
						Intervals[i].edge_start_cl = Intervals[i].edge_start_offset/8;	
				}		
			}	
			Intervals[i].interval_id = i;
			Intervals[i].no_of_active_vertex = 0;
			Intervals[i].update_buffer_counter = 0;
			Intervals[i].update_buffer = (unsigned int *) malloc(sizeof(unsigned int)*MaxUpdateBufferSize);
			for(j=0; j<MaxUpdateBufferSize; j++)
				Intervals[i].update_buffer[j] = 0;
		}		
		Intervals[0].no_of_active_vertex=1;
		
		//for(i=0; i<P; i++){cout<<Intervals[i].edge_start_cl << " "<<Intervals[i].edge_end_cl<<" "<<Intervals[i].edge_start_offset<<" "<<Intervals[i].edge_end_offset<<endl;}
	
		//------------------------------------------------------------------
		
	  ::memset(pVAFU2_cntxt, 0, sizeof(VAFU2_CNTXT));
      //pVAFU2_cntxt->num_cl  = 4096;
      //pVAFU2_cntxt->pSource = pSource_V;
      //pVAFU2_cntxt->pDest   = pDest;
	  pVAFU2_cntxt->dword0  = ((call_counter-1)<<11);	  		  	 
	  struct timespec start, stop; 
	  double exe_time;	  
	  double total_time = 0;	
	  int thread_id;
	  m_SPLService->StartTransactionContext(TransactionID(), pWSUsrVirt, 100);
      m_Sem.Wait();
	  while(have_update){
	 		have_update = 0;
	 		if( clock_gettime(CLOCK_REALTIME, &start) == -1) { perror("clock gettime");}
		 //----------------------------scatter------------------------------	
		#pragma omp parallel num_threads(2) shared(Intervals, pSource_V, pSource_E, vertex_set, current_level) private(i, j, k, p,q, interval_id) 
		{	
				#pragma omp sections private(i, p, q, interval_id)
				{  
					#pragma omp section
					{		
						for(p=workload_of_FPGA; p<10; p++){ 
							  pVAFU2_cntxt->num_cl  = 4096;
					      	  pVAFU2_cntxt->pSource = pSource_V+p*4096*64;
							  pVAFU2_cntxt->dword0  = (call_counter<<11)+control_1+current_level;
						       done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
						      while ((done !=call_counter)) {
						         SleepMilli( delay );
						         done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
						      }    
						      call_counter++;           
						     
							  // read edges	  				  			      
						      pVAFU2_cntxt->pDest     = pDest;
						      pVAFU2_cntxt->pSource = pSource_E+Intervals[p].edge_start_cl*64;				   
							  pVAFU2_cntxt->num_cl  = Intervals[p].edge_end_cl-Intervals[p].edge_start_cl+20;
						      pVAFU2_cntxt->dword0  = (call_counter<<11)+control_2+current_level;
						      
							  //cout <<  pVAFU2_cntxt->num_cl <<endl;     
						       done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
						      while ((done!=call_counter)) {
						        SleepMilli( delay );
						         done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
						      }            
						      call_counter++;
						     
						      FPGA_no_of_writes = ((pVAFU2_cntxt->Status)>>11)  & FPGA_no_of_writes_mask;  		
								
								#pragma omp critical 
								{
							      if(FPGA_no_of_writes !=0){
										for(q=0; q<16*FPGA_no_of_writes; q++){
											interval_id =  *((unsigned int*)(pDest)+q)/I ;
											Intervals[interval_id].update_buffer[Intervals[interval_id].update_buffer_counter] = *((unsigned int*)(pDest)+q);
											Intervals[interval_id].update_buffer_counter++;	
										}	
									}
								}	
					   }
					}
					#pragma omp section
					{
						for(p=0; p<workload_of_FPGA; p++){
							#pragma omp parallel num_threads(ThreadNum) shared(vertex_set, pSource_V, pSource_E, Intervals, p) private(i, j, k, interval_id, thread_id)
							{
								thread_id = omp_get_thread_num();					
								#pragma omp for schedule(static) 					
								for(k=Intervals[p].edge_start_offset; k<Intervals[p].edge_end_offset; k++){
									if((*((unsigned char*)(pSource_V)+*((unsigned int*)(pSource_E)+k*2+1))==current_level) & (*((unsigned int*)(pSource_E)+k*2+1)%64<61)){													
										interval_id=*((unsigned int*)(pSource_E)+k*2+0)/I;	
										UpdateBufferCache[thread_id][interval_id][LocalUpdateBufferCounter[thread_id][interval_id]] = *((unsigned int*)(pSource_E)+k*2+0);
										LocalUpdateBufferCounter[thread_id][interval_id]++;								
										if(LocalUpdateBufferCounter[thread_id][interval_id] == LocalUpdateBufferSize){															
											#pragma omp critical 
											{
												for(j=Intervals[interval_id].update_buffer_counter; j<Intervals[interval_id].update_buffer_counter+LocalUpdateBufferSize; j++){											
													 Intervals[interval_id]. update_buffer[j]	 = UpdateBufferCache[thread_id][interval_id][j-Intervals[interval_id].update_buffer_counter];
												}																					
												Intervals[interval_id].update_buffer_counter+=LocalUpdateBufferSize;
											}
											LocalUpdateBufferCounter[thread_id][interval_id]=0;														
										}	
									}	
								}												
							}
							Intervals[p].no_of_active_vertex = 0;
						}																	
					}
				}
			}		
		
		// Serial flush	buffer cache					
			
			for(thread_id=0; thread_id<ThreadNum; thread_id++){
				for(interval_id=0;	interval_id<P; interval_id++){			
					if(LocalUpdateBufferCounter[thread_id][interval_id]!=0 && LocalUpdateBufferCounter[thread_id][interval_id]<LocalUpdateBufferSize){											
						for(i=Intervals[interval_id].update_buffer_counter; i<Intervals[interval_id].update_buffer_counter+LocalUpdateBufferCounter[thread_id][interval_id]; i++){
						 	Intervals[interval_id].update_buffer[i] = 	UpdateBufferCache[thread_id][interval_id][i-Intervals[interval_id].update_buffer_counter];
						}
						Intervals[interval_id].update_buffer_counter+= LocalUpdateBufferCounter[thread_id][interval_id];
					}											
					LocalUpdateBufferCounter[thread_id][interval_id]=0;
				}
			}
			
				
		#pragma omp parallel for num_threads(ThreadNum)  shared(Intervals, pSource_V) private(p,j) schedule(dynamic) reduction(+:FrontierSize)	   		
		for(p=0; p<P; p++){					
				if(Intervals[p].update_buffer_counter!=0){					
					for(j=0; j<Intervals[p].update_buffer_counter; j++){
						switch(Intervals[p].update_buffer[j]%64) {
						    case 61: 
						    		if((*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]))&15  > current_level+1){
										*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]) = *((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j])&240+current_level+1;							
										Intervals[p].no_of_active_vertex ++;
										FrontierSize++;								
									}
							 break;
						    case 62:
						    		if(((*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1))>>4)&15  > current_level+1){
										*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1) = *((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1)&15+(current_level+1)<<4;							
										Intervals[p].no_of_active_vertex ++;
										FrontierSize++;								
									}
						    break;
						    case 63:
						    		if((*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1))&15  > current_level+1){
										*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1) = *((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]-1)&240+current_level+1;							
										Intervals[p].no_of_active_vertex ++;
										FrontierSize++;								
									}
						    break;	
						    default: 
									if(*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j])  > current_level+1){
										*((unsigned char*)(pSource_V)+Intervals[p].update_buffer[j]) = current_level+1;							
										Intervals[p].no_of_active_vertex ++;
										FrontierSize++;								
									}								    
						    break;
						}															
					}	
				}
				Intervals[p].update_buffer_counter=0;					
			}
			
			current_level++;												
			
			have_update = FrontierSize; 
					 
			
			if( clock_gettime(CLOCK_REALTIME, &stop) == -1) { perror("clock gettime");}
			exe_time = (stop.tv_sec - start.tv_sec)+ (double)(stop.tv_nsec - start.tv_nsec)/1e9;	
			printf("Iteration # %d takes  %f sec, fontier size: %d\n", current_level,  exe_time, FrontierSize);
			total_time = total_time + exe_time;
			FrontierSize=0;	
	} 					
	printf("Total time takes  %f sec\n", total_time );	
     //--------------------------------2nd round------------------------------------  
    /*
      //test_source = 3;	
	  current_level = 1;	
	  
	  ::memset(pVAFU2_cntxt, 0, sizeof(VAFU2_CNTXT));
	  	pVAFU2_cntxt->num_cl  = 4096;
    	pVAFU2_cntxt->pSource = pSource_V;	  
	  //*((unsigned char*)(pSource_V)+test_source) = current_level;
	  
	   pVAFU2_cntxt->dword0  = (call_counter<<11)+control_1+current_level;
	   while ((done !=call_counter)) {
	       SleepMilli( delay );
	       done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
	    }
	    call_counter=call_counter+1;
	  
	  	::memset(pVAFU2_cntxt, 0, sizeof(VAFU2_CNTXT));
	  	pVAFU2_cntxt->pSource = pSource_E;
	    pVAFU2_cntxt->pDest   = pDest;
	  	pVAFU2_cntxt->dword0  = (call_counter<<11)+final_run+control_2+current_level;
    	pVAFU2_cntxt->num_cl  = 4096;
	        
      while ((done!=call_counter)) {
         SleepMilli( delay );
         done = ((pVAFU2_cntxt->Status)>>1)  & call_counter_mask;
      }
                 
       call_counter++;
     
 		FPGA_no_of_writes = ((pVAFU2_cntxt->Status)>>11)  & FPGA_no_of_writes_mask;  		
			
		if(FPGA_no_of_writes !=0){					
			for(q=0; q<16*FPGA_no_of_writes; q++){
				cout << *((unsigned int*)(pDest)+q) <<" ";						
			}	
		}
				
      //for(i=0; i<100; i++){cout<<*((unsigned int*)(pSource)+i)<<"  "<<*((unsigned int*)(pDest)+i)<<endl;}
      //printf("%d\n", pVAFU2_cntxt->Status);       
      //printf("%d\n", (((pVAFU2_cntxt->Status)>>11)  & 1023));*/
      
   ////////////////////////////////////////////////////////////////////////////
   // Clean up and exit
   pVAFU2_cntxt->num_cl  = 1;
   pVAFU2_cntxt->dword0  = (call_counter<<11)+final_run;
   INFO("Workspace verification complete, freeing workspace.");
   m_SPLService->WorkspaceFree(m_pWkspcVirt, TransactionID());
   m_Sem.Wait();

   m_runtimClient->end();   
   
   return m_Result;
}

// We must implement the IServiceClient interface (IServiceClient.h):

// <begin IServiceClient interface>
void ECP::serviceAllocated(IBase               *pServiceBase,
                              TransactionID const &rTranID)
{
   m_pAALService = pServiceBase;
   ASSERT(NULL != m_pAALService);

   // Documentation says SPLAFU Service publishes ISPLAFU as subclass interface
   m_SPLService = subclass_ptr<ISPLAFU>(pServiceBase);

   ASSERT(NULL != m_SPLService);
   if ( NULL == m_SPLService ) {
      return;
   }

   MSG("Service Allocated");

   // Allocate Workspaces needed. ASE runs more slowly and we want to watch the transfers,
   //   so have fewer of them.
#if defined ( ASEAFU )
#define LB_BUFFER_SIZE CL(1255360)
#else
#define LB_BUFFER_SIZE CL(1255360)
#endif

   m_SPLService->WorkspaceAllocate(sizeof(VAFU2_CNTXT) + LB_BUFFER_SIZE + LB_BUFFER_SIZE,
      TransactionID());

}

void ECP::serviceAllocateFailed(const IEvent &rEvent)
{
   IExceptionTransactionEvent * pExEvent = dynamic_ptr<IExceptionTransactionEvent>(iidExTranEvent, rEvent);
   ERR("Failed to allocate a Service");
   ERR(pExEvent->Description());
   ++m_Result;
   m_Sem.Post(1);
}

void ECP::serviceFreed(TransactionID const &rTranID)
{
   MSG("Service Freed");
   // Unblock Main()
   m_Sem.Post(1);
}

// <ISPLClient>
void ECP::OnWorkspaceAllocated(TransactionID const &TranID,
                                  btVirtAddr           WkspcVirt,
                                  btPhysAddr           WkspcPhys,
                                  btWSSize             WkspcSize)
{
   AutoLock(this);

   m_pWkspcVirt = WkspcVirt;
   m_WkspcSize = WkspcSize;
	//m_WkspcSize = 160*CL(1);
	
   INFO("Got Workspace");         // Got workspace so unblock the Run() thread
   m_Sem.Post(1);
}

void ECP::OnWorkspaceAllocateFailed(const IEvent &rEvent)
{
   IExceptionTransactionEvent * pExEvent = dynamic_ptr<IExceptionTransactionEvent>(iidExTranEvent, rEvent);
   ERR("OnWorkspaceAllocateFailed");
   ERR(pExEvent->Description());
   ++m_Result;
   m_Sem.Post(1);
}

void ECP::OnWorkspaceFreed(TransactionID const &TranID)
{
   ERR("OnWorkspaceFreed");
   // Freed so now Release() the Service through the Services IAALService::Release() method
   (dynamic_ptr<IAALService>(iidService, m_pAALService))->Release(TransactionID());
}

void ECP::OnWorkspaceFreeFailed(const IEvent &rEvent)
{
   IExceptionTransactionEvent * pExEvent = dynamic_ptr<IExceptionTransactionEvent>(iidExTranEvent, rEvent);
   ERR("OnWorkspaceAllocateFailed");
   ERR(pExEvent->Description());
   ++m_Result;
   m_Sem.Post(1);
}

/// CMyApp Client implementation of ISPLClient::OnTransactionStarted
void ECP::OnTransactionStarted( TransactionID const &TranID,
                                   btVirtAddr           AFUDSMVirt,
                                   btWSSize             AFUDSMSize)
{
   INFO("Transaction Started");
   m_AFUDSMVirt = AFUDSMVirt;
   m_AFUDSMSize =  AFUDSMSize;
   m_Sem.Post(1);
}
/// CMyApp Client implementation of ISPLClient::OnContextWorkspaceSet
void ECP::OnContextWorkspaceSet( TransactionID const &TranID)
{
   INFO("Context Set");
   m_Sem.Post(1);
}
/// CMyApp Client implementation of ISPLClient::OnTransactionFailed
void ECP::OnTransactionFailed( const IEvent &rEvent)
{
   IExceptionTransactionEvent * pExEvent = dynamic_ptr<IExceptionTransactionEvent>(iidExTranEvent, rEvent);
   MSG("Runtime AllocateService failed");
   MSG(pExEvent->Description());
   m_bIsOK = false;
   ++m_Result;
   m_AFUDSMVirt = NULL;
   m_AFUDSMSize =  0;
   ERR("Transaction Failed");
   m_Sem.Post(1);
}
/// CMyApp Client implementation of ISPLClient::OnTransactionComplete
void ECP::OnTransactionComplete( TransactionID const &TranID)
{
   m_AFUDSMVirt = NULL;
   m_AFUDSMSize =  0;
   INFO("Transaction Complete");
   m_Sem.Post(1);
}
/// CMyApp Client implementation of ISPLClient::OnTransactionStopped
void ECP::OnTransactionStopped( TransactionID const &TranID)
{
   m_AFUDSMVirt = NULL;
   m_AFUDSMSize =  0;
   INFO("Transaction Stopped");
   m_Sem.Post(1);
}
void ECP::serviceEvent(const IEvent &rEvent)
{
   ERR("unexpected event 0x" << hex << rEvent.SubClassID());
}
// <end IServiceClient interface>

/// @} group SudokuSample


//=============================================================================
// Name: main
// Description: Entry point to the application
// Inputs: none
// Outputs: none
// Comments: Main initializes the system. The rest of the example is implemented
//           in the objects.
//=============================================================================
int main(int argc, char *argv[])
{
   RuntimeClient  runtimeClient;
   ECP theApp(&runtimeClient, argv[1]);

   if(!runtimeClient.isOK()){
      ERR("Runtime Failed to Start");
      exit(1);
   }
   btInt Result = theApp.run();

   MSG("Done");
   return Result;
}
