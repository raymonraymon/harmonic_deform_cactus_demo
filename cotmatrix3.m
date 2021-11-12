function K = cotmatrix3(V,T)
  % COTMATRIX3 computes cotangent matrix for 3D tetmeshes, area/mass terms
  % already cancelled out: laplacian mesh operator Following definition that
  % appears in the appendix of: ``Interactive Topology-aware Surface
  % Reconstruction,'' by Sharf, A. et al
  % http://www.cs.bgu.ac.il/~asharf/Projects/InSuRe/Insure_siggraph_final.pdf
  %
  % K = cotmatrix(V,T)
  % Inputs:
  %   V  #V x 3 matrix of vertex coordinates
  %   T  #T x 4  matrix of indices of tetrahedral corners
  % Output:
  %   K  #V x #V matrix of cot weights 
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
  % See also cotmatrix
  %

  if(size(T,1) == 4 && size(T,2) ~=4)
    warning('T seems to be 4 by #T, it should be #T by 4');
  end
  T = T';

  % Jacobian 
  % size(T,2) stacked jacobians (one per tetrahedron)
  J = [ ...
    V(T(1,:),1) - V(T(4,:),1), ...
      V(T(2,:),1) - V(T(4,:),1), ...
      V(T(3,:),1) - V(T(4,:),1), ...
    V(T(1,:),2) - V(T(4,:),2), ...
      V(T(2,:),2) - V(T(4,:),2), ...
      V(T(3,:),2) - V(T(4,:),2), ...
    V(T(1,:),3) - V(T(4,:),3), ...
      V(T(2,:),3) - V(T(4,:),3), ...
      V(T(3,:),3) - V(T(4,:),3), ...
    ];
  i = [ 
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+3)', ...
    (3*((1:size(T,2))-1)+3)', ...
    (3*((1:size(T,2))-1)+3)', ...
    ];
  j = [ 
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+3)', ...
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+3)', ...
    (3*((1:size(T,2))-1)+1)', ...
    (3*((1:size(T,2))-1)+2)', ...
    (3*((1:size(T,2))-1)+3)', ...
    ];
  % sparse jacobian blocks along diagonal
  Jsp = sparse(i,j,J);

  % stacked right hand side
  rhs = [1,0,0,-1;0,1,0,-1;0,0,1,-1];
  rhs = repmat(rhs,size(T,2),1);

  % stacked E matrices
  E = Jsp'\rhs;
  detJ = ...
    J(:,1).*J(:,5).*J(:,9) + ...
    J(:,2).*J(:,6).*J(:,7) + ...
    J(:,3).*J(:,4).*J(:,8) - ...
    J(:,1).*J(:,6).*J(:,8) - ...
    J(:,2).*J(:,4).*J(:,9) - ...
    J(:,3).*J(:,5).*J(:,7);

  i = [(1:size(E,1))', (1:size(E,1))', (1:size(E,1))', (1:size(E,1))'];
  j = floor((i-1)./3)*4 + [ones(size(E,1),1), 2*ones(size(E,1),1), 3*ones(size(E,1),1), 4*ones(size(E,1),1)];
  % stacked E' * E matrices
  ETE = sparse(i,j,E)'*E;

  detJ = repmat(reshape(repmat(detJ',4,1),size(ETE,1),1),1,4);
  % Stacked K matrices
  K = detJ.*ETE./6;

  % at this point every 4x4 block in K should be symmetric

  % Sum up Ks into full size(V,1) by size(V,1) sparse matrix
  % row indices in big K for each value in stacked K
  i = repmat(T(:),4,1);
  % col indices in big K for each value in stacked K
  j = T(:,repmat(1:size(T,2),4,1))';
  j = j(:);
  Kimperfect = sparse(i,j,K,size(V,1),size(V,1));

  % K should be square symmetric, up to double precision
  assert(normest(Kimperfect-Kimperfect') < 1e-14);
  % force K to be perfectly symmetric, add upper triangle to transpose of
  % upper triangle
  K  = triu(Kimperfect) + triu(Kimperfect,1)';
  assert(normest(Kimperfect-K)<1e-14);
  % K should be square (perfectly) symmetric
  assert(isequal(K,K'));

  % perhaps K should be multiplied by 2 to match finite difference stencil and
  % the output of cotmatrix (2D)

  % flip sign to match cotmatix.m
  if(all(diag(K)>0))
    warning('Flipping sign of cotmatrix3, so that diag is negative');
    K = -K;
  end

end
