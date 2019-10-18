USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_1,
    SIZE = 180GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_2,
    SIZE = 80GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_3,
    SIZE = 80GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_4,
    SIZE = 80GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_5,
    SIZE = 80GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_6,
    SIZE = 80GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_7,
    SIZE = 100GB);
GO

USE master;
GO
ALTER DATABASE ngprod 
MODIFY FILE
    (NAME = NextGen_Index_8,
    SIZE = 180GB);
GO

