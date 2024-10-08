      subroutine matrd1(n,z,c,nn,nn1,a,snr,rnr)                                 
c                                                                               
c                                                                               
c  a matrix which depends on two parameters(n-the dimension of the mat-         
c  rix and c-a structure parameter)is generated by the subroutine matrd1        
c  the non-zero elements of the matrix (in any order) are stored                
c  in the first  z  positions (z  is the number of the non-zero                 
c  elements) of the one-dimensional array  a ,  their column and                
c  row numbers in the corresponding positions of array  snr  and                
c  array  rnr.                                                                  
c                                                                               
c                                                                               
      implicit real(a-b,g,p,t-v),integer(c,f,h-n,r-s,z)                         
      dimension a(nn)                                                           
c     integer*2 snr(nn),rnr(nn1)                                                
      integer snr(nn),rnr(nn1)                                                  
      do 20 i=1,n                                                               
      a(i)=1.0                                                                  
      snr(i)=i                                                                  
   20 rnr(i)=i                                                                  
      do 21 i=1,n                                                               
      r=n+i                                                                     
      s=c+i                                                                     
      a(r)=i+1                                                                  
      if(s.le.n)snr(r)=s                                                        
      if(s.gt.n)snr(r)=s-n                                                      
   21 rnr(r)=i                                                                  
      l=2*n                                                                     
      do 22 i=1,n                                                               
      r=l+i                                                                     
      s=c+i+1                                                                   
      a(r)=-i                                                                   
      if(s.le.n)snr(r)=s                                                        
      if(s.gt.n)snr(r)=s-n                                                      
   22 rnr(r)=i                                                                  
      k=3*n                                                                     
      do 23 i=1,n                                                               
      r=k+i                                                                     
      s=c+i+2                                                                   
      a(r)=16.0                                                                 
      if(s.le.n)snr(r)=s                                                        
      if(s.gt.n)snr(r)=s-n                                                      
   23 rnr(r)=i                                                                  
      rr1=10                                                                    
      rr2=4*n                                                                   
      rr3=1                                                                     
   25 continue                                                                  
      do 26 i=1,rr1                                                             
      a(rr2+i)=100.0*i                                                          
      snr(rr2+i)=n-rr1+i                                                        
      rnr(rr2+i)=rr3                                                            
26    continue                                                                  
      if(rr1.eq.1)    go to 27                                                  
      rr2=rr2+rr1                                                               
      rr1=rr1-1                                                                 
      rr3=rr3+1                                                                 
      go to 25                                                                  
   27 z=4*n+55                                                                  
      return                                                                    
      end                                                                       
